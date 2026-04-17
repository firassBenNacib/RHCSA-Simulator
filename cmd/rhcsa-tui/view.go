package main

import (
	"fmt"
	"regexp"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"rhcsa_exam_vms/internal/catalog"
	"rhcsa_exam_vms/internal/utils"
)

var (
	failLinePattern   = regexp.MustCompile(`(?i)^\[fail\]\s*\[([^\]]*)\]\s*(.*)$`)
	failDetailPattern = regexp.MustCompile(`(?i)^fail\s+(\d+):\s*\[([^\]]*)\]\s*(.*)$`)
)

func catalogReadRelative(root, relative string) (string, error) {
	if relative == "" {
		return "", nil
	}
	return catalog.ReadRelative(root, relative), nil
}

// ── Main View ──────────────────────────────────────────────

// View renders the full TUI screen.
func (m model) View() string {
	if m.width == 0 || m.height == 0 {
		return "Loading RHCSA Simulator…"
	}

	// Build chrome
	header := m.theme.RenderHeader(m.width)
	tabBar := m.theme.RenderTabs(m.activeTab, m.width)
	footer := m.renderFooter(m.width)

	// Build content
	var content string
	if m.useStackedLayout() {
		content = m.renderStackedContent()
	} else {
		content = m.renderWideContent()
	}

	// Assemble
	parts := []string{header, tabBar, content}

	// Search bar (rendered above output/footer when in filter mode)
	if m.filterMode {
		parts = append(parts, m.renderSearchBar(m.width))
	}

	// Status/output panel
	if statusHeight := m.statusPaneHeight(); statusHeight > 0 && !m.filterMode {
		parts = append(parts, m.renderOutput(m.width, statusHeight))
	}

	parts = append(parts, footer)
	result := strings.Join(parts, "\n")

	// Help overlay
	if m.showHelp {
		return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center,
			m.theme.Overlay.Render(m.helpBody()))
	}

	return result
}

// ── Wide layout (side-by-side) ─────────────────────────────

func (m model) renderWideContent() string {
	leftWidth := m.listPaneWidth()
	rightWidth := m.detailPaneWidth()
	ch := m.contentHeight()

	listPane := blockLines(m.renderList(leftWidth, ch), leftWidth, ch)
	detailPane := blockLines(m.renderDetail(rightWidth, ch), rightWidth, ch)
	sepLines := strings.Split(m.renderVerticalSeparator(ch), "\n")

	lines := make([]string, 0, ch)
	for i := 0; i < ch; i++ {
		left := ""
		if i < len(listPane) {
			left = listPane[i]
		}
		sep := ""
		if i < len(sepLines) {
			sep = sepLines[i]
		}
		right := ""
		if i < len(detailPane) {
			right = detailPane[i]
		}
		lines = append(lines, left+sep+right)
	}

	return strings.Join(lines, "\n")
}

// ── Stacked layout (narrow terminals) ──────────────────────

func (m model) renderStackedContent() string {
	ch := m.contentHeight()
	listH := utils.MaxInt(ch/3, 6)
	detailH := ch - listH

	listPane := padRenderedBlock(m.renderList(m.width, listH), m.width, listH)
	rule := m.renderPaneRule(m.width)
	detailPane := padRenderedBlock(m.renderDetail(m.width, detailH), m.width, detailH)

	return lipgloss.JoinVertical(lipgloss.Left, listPane, rule, detailPane)
}

// ── Vertical separator for wide layout ─────────────────────

func (m model) renderVerticalSeparator(height int) string {
	lines := make([]string, height)
	for i := range lines {
		lines[i] = m.renderBorderGlyph("│")
	}
	return strings.Join(lines, "\n")
}

func (m model) renderPaneRule(width int) string {
	return m.renderBorderGlyph(strings.Repeat("─", width))
}

func (m model) renderBorderGlyph(text string) string {
	return lipgloss.NewStyle().Foreground(lipgloss.Color("#243244")).Render(text)
}

func padRenderedBlock(text string, width, height int) string {
	return strings.Join(blockLines(text, width, height), "\n")
}

func blockLines(text string, width, height int) []string {
	lines := strings.Split(text, "\n")
	if len(lines) < height {
		for len(lines) < height {
			lines = append(lines, "")
		}
	} else if len(lines) > height {
		lines = lines[:height]
	}

	for i, line := range lines {
		if lipgloss.Width(line) > width {
			line = lipgloss.NewStyle().MaxWidth(width).Render(line)
			lines[i] = line
		}
		lineWidth := lipgloss.Width(line)
		if lineWidth < width {
			lines[i] = line + strings.Repeat(" ", width-lineWidth)
		}
	}

	return lines
}

// ── List pane ──────────────────────────────────────────────

func (m model) renderList(width, height int) string {
	header := m.renderListHeader(width)
	bodyHeight := utils.MaxInt(height-len(header), 1)
	items := strings.Split(m.renderListItems(width, bodyHeight), "\n")
	for len(items) < bodyHeight {
		items = append(items, "")
	}
	if len(items) > bodyHeight {
		items = items[:bodyHeight]
	}
	return strings.Join(append(header, items...), "\n")
}

// listEntry is the data needed to render one list row.
type listEntry struct {
	id       string
	title    string
	selected bool
	active   bool
}

func (m model) renderListHeader(width int) []string {
	var label string
	if m.activeTab == labsTab {
		label = "Labs"
	} else {
		label = "Exams"
	}

	metaParts := []string{m.selectionProgressLabel()}
	if strings.TrimSpace(m.filterQuery) != "" {
		metaParts = append(metaParts, fmt.Sprintf("filter: %q", m.filterQuery))
	}
	metaStyle := m.theme.PaneHeader
	if m.focus == focusList {
		metaStyle = m.theme.PaneHeaderFocused
	}
	line := m.fillLine(
		m.theme.PaneTitle.Render(strings.ToUpper(label)),
		metaStyle.Render(strings.Join(metaParts, "  ·  ")),
		width,
	)
	return []string{
		line,
		m.renderPaneRule(width),
	}
}

func (m model) renderListItems(width, height int) string {
	var entries []listEntry
	var total int

	if m.activeTab == labsTab {
		labs := m.filteredLabs()
		total = len(labs)
		if total == 0 {
			return m.theme.Muted.Render("  No labs found")
		}
		start, end := m.visibleRange(total)
		activeID := m.activeScenarioID()
		for i := start; i < end; i++ {
			lab := labs[i]
			entries = append(entries, listEntry{
				id:       lab.ID,
				title:    lab.Title,
				selected: i == m.selectedLab,
				active:   lab.ID == activeID,
			})
		}
	} else {
		exams := m.filteredExams()
		total = len(exams)
		if total == 0 {
			return m.theme.Muted.Render("  No exams found")
		}
		start, end := m.visibleRange(total)
		activeID := m.activeScenarioID()
		for i := start; i < end; i++ {
			exam := exams[i]
			entries = append(entries, listEntry{
				id:       exam.ID,
				title:    exam.Title,
				selected: i == m.selectedExam,
				active:   exam.ID == activeID,
			})
		}
	}

	lines := make([]string, 0, height)
	for _, e := range entries {
		lines = append(lines, m.renderListRow(e, width))
	}

	return strings.Join(lines, "\n")
}

func (m model) renderListRow(entry listEntry, width int) string {
	innerWidth := utils.MaxInt(width-2, 8)
	title := truncateLine(entry.title, innerWidth-2)
	content := " " + title

	rowStyle := m.theme.ItemNormal
	rail := " "
	if entry.selected {
		rail = m.theme.ItemCursor.Render("▌")
		rowStyle = m.theme.ItemSelectedBlurred
		if m.focus == focusList {
			rowStyle = m.theme.ItemSelected
		}
	} else if entry.active {
		rowStyle = m.theme.ItemRunning
	}

	return rail + rowStyle.Width(innerWidth).Render(content)
}

// ── Detail pane ────────────────────────────────────────────

func (m model) renderDetail(width, height int) string {
	header := m.renderDetailHeaderLines(width)
	bodyHeight := utils.MaxInt(height-len(header), 1)
	lines := strings.Split(m.renderDetailBody(), "\n")
	offset := m.currentDetailOffset()
	if offset > 0 && offset < len(lines) {
		lines = lines[offset:]
	}
	for len(lines) < bodyHeight {
		lines = append(lines, "")
	}
	if len(lines) > bodyHeight {
		lines = lines[:bodyHeight]
	}
	return strings.Join(append(header, lines...), "\n")
}

type scenarioView struct {
	id          string
	title       string
	description string
	minutes     int
	tags        []string
	active      bool
	progress    string
	body        string
}

func (m model) currentScenarioView() scenarioView {
	activeID := m.activeScenarioID()
	if m.activeTab == labsTab {
		lab := m.currentLab()
		body := lab.HintContent
		switch m.detail {
		case detailSolution:
			body, _ = catalogReadRelative(m.root, lab.SolutionPath)
		case detailCheck:
			body = lab.CheckContent
		case detailPrompt:
			body, _ = catalogReadRelative(m.root, lab.TasksPath)
		}
		return scenarioView{
			id:          lab.ID,
			title:       lab.Title,
			description: lab.Description,
			minutes:     lab.TimeLimitMinute,
			tags:        append([]string{}, lab.ObjectiveTags...),
			active:      lab.ID != "" && lab.ID == activeID,
			progress:    m.progressMarker(lab.ID),
			body:        body,
		}
	}

	exam := m.currentExam()
	body, _ := catalogReadRelative(m.root, exam.TasksPath)
	if m.detail == detailSolution {
		body, _ = catalogReadRelative(m.root, exam.SolutionPath)
	}
	return scenarioView{
		id:          exam.ID,
		title:       exam.Title,
		description: exam.Description,
		minutes:     exam.TimeLimitMinute,
		tags:        append([]string{}, exam.ObjectiveTags...),
		active:      exam.ID != "" && exam.ID == activeID,
		progress:    m.examProgressMarker(exam.ID),
		body:        body,
	}
}

func (m model) renderDetailHeaderLines(width int) []string {
	view := m.currentScenarioView()
	if view.id == "" {
		return []string{m.theme.Muted.Render("No scenario selected")}
	}

	tabs := m.theme.RenderViewModes(m.detail, m.activeTab == examsTab)
	copyAction := ""
	if m.canCopyDetail() {
		copyAction = m.theme.RenderCopyButton()
	}
	title := m.theme.PaneTitle.Render("  " + truncateLine(view.title, utils.MaxInt(width-2, 1)))
	metaParts := []string{view.id, fmt.Sprintf("%d min", view.minutes)}
	if systems := extractSystemsFromDocument(view.body); len(systems) > 0 {
		metaParts = append(metaParts, strings.Join(systems, " / "))
	}
	if view.active {
		metaParts = append(metaParts, m.theme.ActiveBadge.Render("ACTIVE"))
	}
	if status := m.theme.StatusBadge(view.progress); status != "" {
		metaParts = append(metaParts, status)
	}
	subtitle := sanitizeScenarioSentence(view.description)
	if subtitle != "" {
		metaParts = append(metaParts, subtitle)
	}

	lines := []string{
		m.fillLine(tabs, copyAction, width),
		m.renderPaneRule(width),
		title,
	}
	if meta := strings.Join(metaParts, "  ·  "); meta != "" {
		metaStyle := m.theme.PaneHeader
		if m.focus == focusDetail {
			metaStyle = m.theme.PaneHeaderFocused
		}
		lines = append(lines, metaStyle.Render("  "+truncateLine(meta, utils.MaxInt(width-2, 1))))
	}

	lines = append(lines, m.renderPaneRule(width))
	return lines
}

func (m model) renderDetailBody() string {
	view := m.currentScenarioView()
	if view.id == "" {
		return m.theme.Muted.Render("No scenario selected")
	}
	body := trimDocumentHeading(view.title, m.detail, sanitizeScenarioDocument(view.description, view.body))
	body = trimActionSectionBoilerplate(body)
	rendered := m.processMarkdown(body, m.detailTextWidth(), m.detail)
	return rendered
}

func (m model) canCopyDetail() bool {
	return m.detail == detailCheck || m.detail == detailSolution
}

func (m model) copyableDetailBody() string {
	view := m.currentScenarioView()
	if view.id == "" {
		return ""
	}
	body := strings.TrimSpace(trimDocumentHeading(view.title, m.detail, sanitizeScenarioDocument(view.description, view.body)))
	body = trimActionSectionBoilerplate(body)
	return strings.TrimSpace(body)
}

func sanitizeScenarioSentence(text string) string {
	replacer := strings.NewReplacer(
		" in RHCSA style.", ".",
		" in RHCSA style", "",
		" RHCSA style", "",
		"RHCSA-style ", "",
	)
	clean := strings.TrimSpace(replacer.Replace(text))
	clean = strings.ReplaceAll(clean, "  ", " ")
	return clean
}

func sanitizeScenarioDocument(description, content string) string {
	content = strings.ReplaceAll(content, "\r\n", "\n")
	lines := strings.Split(content, "\n")
	sanitized := make([]string, 0, len(lines))
	description = strings.TrimSpace(sanitizeScenarioSentence(description))

	for _, rawLine := range lines {
		line := sanitizeScenarioSentence(rawLine)
		trimmed := strings.TrimSpace(line)

		if trimmed == "## Overview" {
			continue
		}
		if shouldHideOverviewLine(trimmed) {
			continue
		}
		if description != "" && strings.EqualFold(trimmed, description) {
			continue
		}

		sanitized = append(sanitized, line)
	}

	return strings.TrimSpace(compactBlankLines(sanitized))
}

func trimActionSectionBoilerplate(content string) string {
	lines := strings.Split(strings.ReplaceAll(content, "\r\n", "\n"), "\n")
	filtered := make([]string, 0, len(lines))
	skipSection := false

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "### Systems" || trimmed == "## General Instructions" {
			skipSection = true
			continue
		}
		if skipSection {
			if strings.HasPrefix(trimmed, "## ") || strings.HasPrefix(trimmed, "### ") {
				skipSection = false
			} else {
				continue
			}
		}
		filtered = append(filtered, line)
	}

	return strings.TrimSpace(compactBlankLines(filtered))
}

func extractSystemsFromDocument(content string) []string {
	lines := strings.Split(strings.ReplaceAll(content, "\r\n", "\n"), "\n")
	systems := make([]string, 0, 2)
	seen := map[string]bool{}
	inSystems := false

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "### Systems" || trimmed == "## Systems" {
			inSystems = true
			continue
		}
		if !inSystems {
			continue
		}
		if strings.HasPrefix(trimmed, "## ") || strings.HasPrefix(trimmed, "### ") {
			break
		}
		for _, prefix := range []string{"- ", "* ", "+ "} {
			if strings.HasPrefix(trimmed, prefix) {
				system := strings.TrimSpace(strings.TrimPrefix(trimmed, prefix))
				if system != "" && !seen[system] {
					seen[system] = true
					systems = append(systems, system)
				}
				break
			}
		}
	}

	return systems
}

func shouldHideOverviewLine(trimmed string) bool {
	if trimmed == "" {
		return false
	}
	converted, ok := simplifyMarkdownTableLine(trimmed)
	if !ok {
		return false
	}
	return converted == ""
}

func compactBlankLines(lines []string) string {
	out := make([]string, 0, len(lines))
	lastBlank := true
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			if lastBlank {
				continue
			}
			lastBlank = true
			out = append(out, "")
			continue
		}
		lastBlank = false
		out = append(out, line)
	}
	return strings.Join(out, "\n")
}

// ── Markdown processor ─────────────────────────────────────

func (m model) processMarkdown(content string, width int, mode detailMode) string {
	lines := strings.Split(stripMarkdownBold(content), "\n")
	rendered := make([]string, 0, len(lines))
	inCode := false
	terminalCommands := mode == detailCheck

	for _, rawLine := range lines {
		trimmed := strings.TrimSpace(rawLine)
		if trimmed == "" {
			rendered = append(rendered, "")
			continue
		}

		if strings.HasPrefix(trimmed, "```") {
			inCode = !inCode
			continue
		}

		line := rawLine
		if !inCode {
			line = strings.ReplaceAll(line, "`", "")
			trimmed = strings.TrimSpace(line)
		}

		// Table rows
		if converted, ok := simplifyMarkdownTableLine(trimmed); ok {
			if converted != "" {
				rendered = append(rendered, m.theme.DetailMeta.Render("  "+converted))
			}
			continue
		}

		switch {
		case strings.Trim(trimmed, "-") == "" && len(trimmed) > 2:
			rendered = append(rendered, m.theme.DetailRule.Render("  "+strings.Repeat("─", utils.MinInt(width-8, 60))))
		case inCode:
			if mode == detailSolution || mode == detailCheck {
				rendered = appendCommandLines(rendered, strings.TrimSpace(line), width, m.theme)
			} else {
				rendered = appendWrappedLines(rendered, "  "+line, width, m.theme.DetailCode)
			}
		case strings.HasPrefix(trimmed, "# "):
			rendered = appendWrappedLines(rendered, "  "+strings.TrimPrefix(trimmed, "# "), width, m.theme.DetailH1)
		case strings.HasPrefix(trimmed, "## "):
			rendered = appendWrappedLines(rendered, "  "+strings.TrimPrefix(trimmed, "## "), width, m.theme.DetailH2)
		case strings.HasPrefix(trimmed, "### "):
			rendered = appendWrappedLines(rendered, "  "+strings.TrimPrefix(trimmed, "### "), width, m.theme.DetailH3)
		case strings.HasPrefix(trimmed, "- ") || strings.HasPrefix(trimmed, "* ") || strings.HasPrefix(trimmed, "+ "):
			content := strings.TrimPrefix(strings.TrimPrefix(strings.TrimPrefix(trimmed, "- "), "* "), "+ ")
			rendered = appendWrappedLines(rendered, "  • "+content, width, m.theme.DetailList)
		case terminalCommands:
			rendered = appendCommandLines(rendered, trimmed, width, m.theme)
		default:
			rendered = appendWrappedLines(rendered, "  "+line, width, m.theme.DetailPlain)
		}
	}

	return strings.Join(rendered, "\n")
}

func appendCommandLines(dst []string, line string, width int, theme Theme) []string {
	trimmed := strings.TrimSpace(line)
	if trimmed == "" {
		return append(dst, "")
	}
	if strings.HasPrefix(trimmed, "#") {
		return appendWrappedLines(dst, "  "+trimmed, width, theme.DetailMeta)
	}
	command := strings.TrimPrefix(trimmed, "$ ")
	return appendWrappedLines(dst, "  $ "+command, width, theme.DetailCommand)
}

// ── Text wrapping ──────────────────────────────────────────

func appendWrappedLines(dst []string, line string, width int, style lipgloss.Style) []string {
	if strings.TrimSpace(line) == "" {
		return append(dst, "")
	}
	if width < 12 {
		width = 12
	}
	for _, part := range wrapLine(line, width) {
		dst = append(dst, style.Render(part))
	}
	return dst
}

func wrapLine(line string, width int) []string {
	if width < 1 {
		return []string{""}
	}

	trimmed := strings.TrimSpace(line)
	if trimmed == "" {
		return []string{""}
	}

	leadingSpaces := len(line) - len(strings.TrimLeft(line, " "))
	indent := strings.Repeat(" ", leadingSpaces)
	words := strings.Fields(trimmed)
	if len(words) == 0 {
		return []string{indent}
	}

	lines := make([]string, 0, 4)
	current := indent

	flush := func() {
		if strings.TrimSpace(current) != "" {
			lines = append(lines, current)
		}
	}

	for _, word := range words {
		if lipgloss.Width(indent)+lipgloss.Width(word) > width {
			flush()
			runes := []rune(word)
			for len(runes) > width {
				lines = append(lines, string(runes[:width]))
				runes = runes[width:]
			}
			current = indent + string(runes)
			continue
		}

		var candidate string
		if strings.TrimSpace(current) != "" {
			candidate = current + " " + word
		} else {
			candidate = indent + word
		}

		if lipgloss.Width(candidate) <= width {
			current = candidate
			continue
		}

		flush()
		current = indent + word
	}

	flush()
	if len(lines) == 0 {
		return []string{indent}
	}
	return lines
}

// ── Search bar ─────────────────────────────────────────────

func (m model) renderSearchBar(width int) string {
	label := m.theme.SearchLabel.Render(" Search ")
	query := m.filterQuery + "▏"
	input := m.theme.SearchInput.Width(utils.MaxInt(width-8, 20)).Render(query)
	bar := label + input
	return lipgloss.NewStyle().Width(width).Render(bar)
}

// ── Output / status panel ──────────────────────────────────

func (m model) renderOutput(width, height int) string {
	body := m.statusBody()
	if strings.TrimSpace(body) == "" {
		return ""
	}

	lines := strings.Split(body, "\n")
	rendered := make([]string, 0, len(lines))
	for _, line := range lines {
		rendered = append(rendered, m.statusLineStyle(line).Render(" "+line))
	}

	return m.theme.OutputPanel.Width(width).Height(utils.MinInt(height, 8)).Render(strings.Join(rendered, "\n"))
}

// ── Footer ─────────────────────────────────────────────────

func (m model) renderFooter(width int) string {
	type footerAction struct {
		key   string
		label string
	}

	var actions []footerAction
	if m.filterMode {
		actions = []footerAction{
			{"Enter", "Keep"},
			{"Esc", "Clear"},
			{"q", "Quit"},
		}
	} else {
		actions = []footerAction{
			{"Enter", "Start"},
			{"r", "Reset"},
			{"Tab", "Pane"},
		}
		arrowLabel := "L/E"
		if m.focus == focusDetail {
			arrowLabel = "Docs"
		}
		actions = append(actions, footerAction{"←→", arrowLabel})
		if m.activeTab == labsTab {
			actions = append(actions, footerAction{"c", "Check"})
			actions = append(actions,
				footerAction{"F1", "Tasks"},
				footerAction{"F2", "Hints"},
				footerAction{"F3", "Checks"},
				footerAction{"F4", "Solutions"},
			)
		} else {
			actions = append(actions,
				footerAction{"F1", "Tasks"},
				footerAction{"F4", "Solutions"},
			)
		}
		actions = append(actions,
			footerAction{"/", "Find"},
			footerAction{"?", "Help"},
			footerAction{"q", "Quit"},
		)
	}

	parts := make([]string, 0, len(actions))
	usedWidth := 0
	for _, action := range actions {
		part := m.theme.FooterKey.Render(action.key) + m.theme.FooterValue.Render(" "+action.label)
		partWidth := lipgloss.Width(part)
		if len(parts) > 0 {
			partWidth += 2
		}
		if usedWidth+partWidth > width-2 {
			break
		}
		parts = append(parts, part)
		usedWidth += partWidth
	}

	return m.theme.FooterBar.Width(width).Render(strings.Join(parts, "  "))
}

func (m model) detailCopyButtonBounds() (int, int, int, bool) {
	if !m.canCopyDetail() {
		return 0, 0, 0, false
	}

	detailWidth := m.detailPaneWidth()
	buttonWidth := lipgloss.Width(m.theme.RenderCopyButton())
	if buttonWidth < 1 || detailWidth < buttonWidth {
		return 0, 0, 0, false
	}

	originX, originY := m.detailPaneOrigin()
	startX := originX + detailWidth - buttonWidth
	endX := originX + detailWidth - 1
	return startX, endX, originY, true
}

func (m model) catalogTabBounds() (labsStart, labsEnd, examsStart, examsEnd, y int) {
	y = 1
	x := 2
	labsWidth := lipgloss.Width(m.theme.TabActive.Render("LABS"))
	examsWidth := lipgloss.Width(m.theme.TabActive.Render("EXAMS"))
	labsStart, labsEnd = x, x+labsWidth-1
	x = labsEnd + 1 + 3
	examsStart, examsEnd = x, x+examsWidth-1
	return
}

func (m model) detailTabBounds() map[detailMode][2]int {
	bounds := map[detailMode][2]int{}
	originX, originY := m.detailPaneOrigin()
	_ = originY
	x := originX

	modes := m.availableDetailModes()
	for _, mode := range modes {
		label := detailModeLabel(mode)
		width := lipgloss.Width(m.theme.ViewModeActive.Render(label))
		bounds[mode] = [2]int{x, x + width - 1}
		x += width
	}
	return bounds
}

func (m model) fillLine(left, right string, width int) string {
	leftWidth := lipgloss.Width(left)
	rightWidth := lipgloss.Width(right)
	gap := utils.MaxInt(width-leftWidth-rightWidth, 1)
	return left + strings.Repeat(" ", gap) + right
}

func trimDocumentHeading(title string, mode detailMode, body string) string {
	lines := strings.Split(strings.ReplaceAll(body, "\r\n", "\n"), "\n")
	normalizedTitle := strings.ToLower(strings.TrimSpace(title))
	generic := map[detailMode]map[string]bool{
		detailPrompt:   {"lab tasks": true, "exam tasks": true, normalizedTitle: true},
		detailHint:     {"hint": true, "hints": true, normalizedTitle + " hints": true},
		detailSolution: {"solution": true, "lab solution": true, "exam solution": true, normalizedTitle: true},
		detailCheck:    {"checks": true, "lab checks": true, normalizedTitle: true},
	}

	for len(lines) > 0 {
		if strings.TrimSpace(lines[0]) == "" {
			lines = lines[1:]
			continue
		}
		if !strings.HasPrefix(strings.TrimSpace(lines[0]), "#") {
			break
		}
		heading := strings.TrimSpace(strings.TrimLeft(strings.TrimSpace(lines[0]), "#"))
		normalizedHeading := strings.ToLower(strings.TrimSpace(heading))
		if !generic[mode][normalizedHeading] {
			break
		}
		lines = lines[1:]
	}

	return strings.Join(lines, "\n")
}

func detailModeLabel(mode detailMode) string {
	switch mode {
	case detailPrompt:
		return "TASKS"
	case detailHint:
		return "HINTS"
	case detailCheck:
		return "CHECKS"
	case detailSolution:
		return "SOLUTIONS"
	default:
		return ""
	}
}

// ── Utilities ──────────────────────────────────────────────

func truncateLine(text string, width int) string {
	if width < 1 {
		return ""
	}
	runes := []rune(text)
	if len(runes) <= width {
		return text
	}
	return string(runes[:width-1]) + "…"
}

func stripMarkdownBold(s string) string {
	return strings.ReplaceAll(s, "**", "")
}

func simplifyMarkdownTableLine(trimmed string) (string, bool) {
	if !strings.HasPrefix(trimmed, "|") || !strings.HasSuffix(trimmed, "|") {
		return "", false
	}

	parts := strings.Split(trimmed, "|")
	cells := make([]string, 0, len(parts))
	for _, part := range parts {
		cell := strings.TrimSpace(strings.Trim(part, "`"))
		if cell != "" {
			cells = append(cells, cell)
		}
	}
	if len(cells) == 0 {
		return "", true
	}

	// Separator row (all dashes/colons)
	separator := true
	for _, cell := range cells {
		if strings.Trim(cell, "-:") != "" {
			separator = false
			break
		}
	}
	if separator {
		return "", true
	}

	// Two-column key-value tables
	if len(cells) == 2 {
		left := strings.ToLower(cells[0])
		right := strings.ToLower(cells[1])
		if (left == "field" && right == "value") || (left == "system" && right == "use") {
			return "", true
		}
		switch left {
		case "scenario id", "mode", "time limit", "objectives":
			return "", true
		}
		return fmt.Sprintf("%s: %s", cells[0], cells[1]), true
	}

	return strings.Join(cells, " │ "), true
}

// ── Key matchers ───────────────────────────────────────────

func matchesPromptViewKey(msg tea.KeyMsg) bool {
	switch msg.String() {
	case "1", "kp1", "f1", "&":
		return true
	default:
		return false
	}
}

func matchesHintViewKey(msg tea.KeyMsg) bool {
	normalized := normalizeTerminalText(msg.String())
	switch normalized {
	case "2", "kp2", "f2":
		return true
	}
	return strings.Contains(normalized, "é") || strings.Contains(normalized, "É")
}

func normalizeTerminalText(text string) string {
	normalized := normalizeUnicode(text)
	replacer := strings.NewReplacer(
		"Ã©", "é", "ÃƒÂ©", "é", "Âé", "é",
		"Ã‰", "É", "Ãƒâ€°", "É", "ÂÉ", "É",
	)
	return replacer.Replace(normalized)
}

func filterTextForKey(msg tea.KeyMsg) (string, bool) {
	switch msg.Type {
	case tea.KeySpace:
		return " ", true
	case tea.KeyRunes:
		if len(msg.Runes) == 0 {
			return "", false
		}
		return normalizeTerminalText(string(msg.Runes)), true
	}

	normalized := normalizeTerminalText(msg.String())
	if strings.Contains(normalized, "é") || strings.Contains(normalized, "É") {
		return "é", true
	}
	switch normalized {
	case "é", "É", ":", "/", "&", "\"", "'", ",":
		return normalized, true
	}

	if msg.Type == tea.KeyRunes && len(msg.Runes) > 0 {
		text := normalizeTerminalText(string(msg.Runes))
		if strings.TrimSpace(text) != "" {
			return text, true
		}
	}

	// Accept printable characters, reject control/modifier combos
	if normalized != "" &&
		!strings.Contains(normalized, "ctrl+") &&
		!strings.Contains(normalized, "alt+") &&
		!strings.Contains(normalized, "shift+") &&
		!strings.Contains(normalized, "esc") &&
		!strings.Contains(normalized, "enter") &&
		!strings.Contains(normalized, "backspace") &&
		!strings.Contains(normalized, "delete") &&
		!strings.Contains(normalized, "left") &&
		!strings.Contains(normalized, "right") &&
		!strings.Contains(normalized, "up") &&
		!strings.Contains(normalized, "down") &&
		!strings.Contains(normalized, "tab") &&
		!strings.Contains(normalized, "pg") &&
		!strings.Contains(normalized, "home") &&
		!strings.Contains(normalized, "end") &&
		!strings.HasPrefix(normalized, "f") &&
		!strings.HasPrefix(normalized, "kp") {
		return normalized, true
	}

	return "", false
}

func matchesSolutionViewKey(msg tea.KeyMsg) bool {
	switch msg.String() {
	case "4", "kp4", "f4", "'", "\u2019":
		return true
	default:
		return false
	}
}

func matchesCheckViewKey(msg tea.KeyMsg) bool {
	switch msg.String() {
	case "3", "kp3", "f3", "\"":
		return true
	default:
		return false
	}
}
