package main

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

var (
	failLinePattern    = regexp.MustCompile(`(?i)^\[fail\]\s*\[([^\]]*)\]\s*(.*)$`)
	failDetailPattern  = regexp.MustCompile(`(?i)^fail\s+(\d+):\s*\[([^\]]*)\]\s*(.*)$`)
)

func (m model) View() string {
	if m.width == 0 || m.height == 0 {
		return "Loading RHCSA Simulator…"
	}

	tabBar := m.theme.RenderTabs(m.activeTab, m.width)
	footer := m.renderFooter(m.width)

	var content string
	if m.useStackedLayout() {
		content = m.renderStackedContent()
	} else {
		content = m.renderWideContent()
	}

	parts := []string{tabBar, content}

	if m.filterMode {
		parts = append(parts, m.renderSearchBar(m.width))
	}

	if statusHeight := m.statusPaneHeight(); statusHeight > 0 && !m.filterMode {
		parts = append(parts, m.renderOutput(m.width, statusHeight))
	}

	parts = append(parts, footer)
	result := strings.Join(parts, "\n")

	if m.showHelp {
		return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center,
			m.theme.Overlay.Render(m.renderHelpWithClose()))
	}

	return result
}

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
		line := left + sep + right
		if visible := lipgloss.Width(line); visible < m.width {
			line += strings.Repeat(" ", m.width-visible)
		}
		lines = append(lines, line)
	}

	return strings.Join(lines, "\n")
}

func (m model) renderStackedContent() string {
	ch := m.contentHeight()
	listH := max(ch/3, 6)
	detailH := ch - listH

	listPane := padRenderedBlock(m.renderList(m.width, listH), m.width, listH)
	rule := m.renderPaneRule(m.width)
	detailPane := padRenderedBlock(m.renderDetail(m.width, detailH), m.width, detailH)

	return lipgloss.JoinVertical(lipgloss.Left, listPane, rule, detailPane)
}

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

func (m model) renderList(width, height int) string {
	header := m.renderListHeader(width)
	bodyHeight := max(height-len(header), 1)
	items := strings.Split(m.renderListItems(width, bodyHeight), "\n")
	for len(items) < bodyHeight {
		items = append(items, "")
	}
	if len(items) > bodyHeight {
		items = items[:bodyHeight]
	}
	return strings.Join(append(header, items...), "\n")
}

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

	metaParts := []string{m.trackLabel(), m.selectionProgressLabel()}
	if strings.TrimSpace(m.filterQuery) != "" {
		metaParts = append(metaParts, fmt.Sprintf("filter: %q", m.filterQuery))
	}
	metaStyle := m.theme.PaneHeader
	if m.focus == focusList {
		metaStyle = m.theme.PaneHeaderFocused
	}
	line := m.fillLine(
		m.theme.PaneTitle.Render(strings.ToUpper(label)),
		metaStyle.Render(strings.Join(metaParts, " · ")),
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
			return m.theme.Muted.Render(" No labs found")
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
			return m.theme.Muted.Render(" No exams found")
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
	innerWidth := max(width-2, 8)
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

func (m model) renderSearchBar(width int) string {
	label := m.theme.SearchLabel.Render("Search ")
	query := m.filterQuery + "▏"
	input := m.theme.SearchInput.Render(query)
	return truncateOrPadRenderedLine(label+input, width)
}

func (m model) renderOutput(width, height int) string {
	body := m.statusBody()
	if strings.TrimSpace(body) == "" {
		return ""
	}

	lines := strings.Split(body, "\n")
	rendered := make([]string, 0, height)
	rendered = append(rendered, m.fillLine(m.theme.OutputTitle.Render("Output"), "", width))
	rendered = append(rendered, m.renderPaneRule(width))
	for _, line := range lines {
		rendered = append(rendered, truncateOrPadRenderedLine(m.statusLineStyle(line).Render(" "+line), width))
	}
	for len(rendered) < height {
		rendered = append(rendered, strings.Repeat(" ", width))
	}
	if len(rendered) > height {
		rendered = rendered[:height]
	}
	return strings.Join(rendered, "\n")
}

func truncateOrPadRenderedLine(line string, width int) string {
	if lipgloss.Width(line) > width {
		line = lipgloss.NewStyle().MaxWidth(width).Render(line)
	}
	visible := lipgloss.Width(line)
	if visible < width {
		line += strings.Repeat(" ", width-visible)
	}
	return line
}

func (m model) catalogTabBounds() (labsStart, labsEnd, examsStart, examsEnd, y int) {
	y = 0
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
	x, _ := m.detailPaneOrigin()

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
	gap := max(width-leftWidth-rightWidth, 1)
	return left + strings.Repeat(" ", gap) + right
}
