package main

import (
	"fmt"
	"strings"

	"github.com/firassBenNacib/rhcsa_exam_vms/internal/catalog"

	"github.com/charmbracelet/lipgloss"
)

func (m model) renderDetail(width, height int) string {
	header := m.renderDetailHeaderLines(width)
	bodyHeight := max(height-len(header), 1)
	bodyLines := m.renderDetailBodyLines(m.detailTextWidth())
	lines := make([]string, 0, len(bodyLines))
	for _, line := range bodyLines {
		lines = append(lines, line.text)
	}
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

type detailRenderedLine struct {
	text         string
	copySection  int
}

type copySection struct {
	title   string
	content string
}

func (m model) currentScenarioView() scenarioView {
	activeID := m.activeScenarioID()
	if m.activeTab == labsTab {
		lab := m.currentLab()
		body := lab.HintContent
		switch m.detail {
		case detailSolution:
			body = catalog.ReadRelative(m.root, lab.SolutionPath)
		case detailCheck:
			body = lab.CheckContent
		case detailPrompt:
			body = catalog.ReadRelative(m.root, lab.TasksPath)
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
	body := catalog.ReadRelative(m.root, exam.TasksPath)
	if m.detail == detailSolution {
		body = catalog.ReadRelative(m.root, exam.SolutionPath)
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
	title := m.theme.PaneTitle.Render(" " + truncateLine(view.title, max(width-3, 1)))
	metaParts := []string{view.id, fmt.Sprintf("%d min", view.minutes)}
	if systems := extractSystemsFromDocument(view.body); len(systems) > 0 {
		metaParts = append(metaParts, strings.Join(systems, " / "))
	}
	if status := m.theme.StatusBadge(view.progress); status != "" {
		metaParts = append(metaParts, status)
	}
	lines := []string{
		m.fillLine(tabs, "", width),
		m.renderPaneRule(width),
		title,
	}
	if meta := strings.Join(metaParts, " · "); meta != "" {
		metaStyle := m.theme.PaneHeader
		if m.focus == focusDetail {
			metaStyle = m.theme.PaneHeaderFocused
		}
		lines = append(lines, metaStyle.Render(" "+truncateLine(meta, max(width-2, 1))))
	}

	lines = append(lines, m.renderPaneRule(width))
	return lines
}

func (m model) renderDetailBody() string {
	lines := m.renderDetailBodyLines(m.detailTextWidth())
	parts := make([]string, 0, len(lines))
	for _, line := range lines {
		parts = append(parts, line.text)
	}
	return strings.Join(parts, "\n")
}

func (m model) renderDetailBodyLines(width int) []detailRenderedLine {
	view := m.currentScenarioView()
	if view.id == "" {
		return []detailRenderedLine{{text: m.theme.Muted.Render("No scenario selected"), copySection: -1}}
	}
	body := trimDocumentHeading(view.title, m.detail, sanitizeScenarioDocument(view.description, view.body))
	body = trimActionSectionBoilerplate(body)
	return m.processMarkdownLines(body, width, m.detail)
}

func (m model) canCopyDetail() bool {
	return m.detail == detailCheck || m.detail == detailSolution
}

func cleanCopyText(text string) string {
	lines := strings.Split(strings.ReplaceAll(text, "\r\n", "\n"), "\n")
	cleaned := make([]string, 0, len(lines))
	inCode := false
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "```") {
			inCode = !inCode
			continue
		}
		if !inCode && strings.Trim(trimmed, "-") == "" && len(trimmed) > 2 {
			continue
		}
		if !inCode {
			line = strings.ReplaceAll(line, "`", "")
			line = stripMarkdownBold(line)
		}
		cleaned = append(cleaned, line)
	}
	return strings.TrimSpace(compactBlankLines(cleaned))
}

func (m model) rawDetailBody() string {
	view := m.currentScenarioView()
	if view.id == "" {
		return ""
	}
	body := strings.TrimSpace(trimDocumentHeading(view.title, m.detail, sanitizeScenarioDocument(view.description, view.body)))
	body = trimActionSectionBoilerplate(body)
	return body
}

func (m model) copyableDetailBody() string {
	return cleanCopyText(m.rawDetailBody())
}

func (m model) copyableSections() []copySection {
	if !m.canCopyDetail() {
		return nil
	}

	rawBody := m.rawDetailBody()
	if rawBody == "" {
		return nil
	}

	lines := strings.Split(strings.ReplaceAll(rawBody, "\r\n", "\n"), "\n")
	sections := make([]copySection, 0, 8)
	var current *copySection
	var currentLines []string
	inCode := false

	flush := func() {
		if current == nil {
			return
		}
		current.content = cleanCopyText(strings.Join(currentLines, "\n"))
		if strings.TrimSpace(current.content) != "" {
			sections = append(sections, *current)
		}
		current = nil
		currentLines = nil
	}

	for _, raw := range lines {
		trimmed := strings.TrimSpace(raw)
		if strings.HasPrefix(trimmed, "```") {
			inCode = !inCode
			if current != nil {
				currentLines = append(currentLines, raw)
			}
			continue
		}

		if !inCode {
			line := strings.ReplaceAll(raw, "`", "")
			line = stripMarkdownBold(line)
			normalized, ok := normalizedSectionHeading(strings.TrimSpace(strings.TrimLeft(strings.TrimSpace(line), "#")))
			if ok {
				flush()
				current = &copySection{title: normalized}
				continue
			}
		}

		if current != nil {
			currentLines = append(currentLines, raw)
		}
	}
	flush()

	if len(sections) == 0 {
		cleaned := m.copyableDetailBody()
		if strings.TrimSpace(cleaned) != "" {
			return []copySection{{title: "SECTION", content: strings.TrimSpace(cleaned)}}
		}
	}

	return sections
}

func sanitizeScenarioSentence(text string) string {
	replacer := strings.NewReplacer(
		" in RHCSA style.", ".",
		" in RHCSA style", "",
		" RHCSA style", "",
		"RHCSA-style ", "",
	)
	clean := strings.TrimSpace(replacer.Replace(text))
	clean = strings.ReplaceAll(clean, "	", " ")
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

func (m model) detailSectionOffsets() []int {
	lines := m.renderDetailBodyLines(m.detailTextWidth())
	offsets := make([]int, 0, 8)
	for i, line := range lines {
		stripped := strings.TrimSpace(StripAnsi(line.text))
		if _, ok := normalizedSectionHeading(stripped); ok {
			offsets = append(offsets, i)
		}
	}
	return offsets
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
