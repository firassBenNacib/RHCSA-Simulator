package main

import (
	"fmt"
	"regexp"
	"strings"
	"unicode"

	"github.com/charmbracelet/lipgloss"
)

var sectionTitlePattern = regexp.MustCompile(`(?i)^(?:task|check|question|hint)\s+\d+\b.*$`)

func (m model) processMarkdownLines(content string, width int, mode detailMode) []detailRenderedLine {
	lines := strings.Split(stripMarkdownBold(content), "\n")
	rendered := make([]detailRenderedLine, 0, len(lines))
	inCode := false
	terminalCommands := mode == detailCheck
	copySectionIndex := -1
	copySections := m.copyableSections()
	showCopyButtons := m.canCopyDetail()
	if showCopyButtons && len(copySections) == 1 && copySections[0].title == "SECTION" {
		rendered = append(rendered, m.renderCopyableHeadingLine("Copy Section", width, 0)...)
		rendered = append(rendered, detailRenderedLine{text: "", copySection: -1})
		copySectionIndex = 0
	}

	for _, rawLine := range lines {
		trimmed := strings.TrimSpace(rawLine)
		if trimmed == "" {
			rendered = append(rendered, detailRenderedLine{text: "", copySection: -1})
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
		if converted, ok := simplifyMarkdownTableLine(trimmed); ok {
			if converted != "" {
				rendered = append(rendered, detailRenderedLine{text: m.theme.DetailMeta.Render(" " + converted), copySection: -1})
			}
			continue
		}

		switch {
		case strings.Trim(trimmed, "-") == "" && len(trimmed) > 2:
			rendered = append(rendered, detailRenderedLine{text: m.theme.DetailRule.Render(" " + strings.Repeat("─", min(width-8, 60))), copySection: -1})
		case inCode:
			if mode == detailSolution || mode == detailCheck {
				rendered = appendCommandLines(rendered, strings.TrimSpace(line), width, m.theme)
			} else {
				rendered = appendWrappedDetailLines(rendered, " "+line, width, m.theme.DetailCode)
			}
		case strings.HasPrefix(trimmed, "# "):
			heading := strings.TrimPrefix(trimmed, "# ")
			if _, ok := normalizedSectionHeading(heading); ok {
				if showCopyButtons {
					copySectionIndex++
					rendered = append(rendered, m.renderCopyableHeadingLine(heading, width, sectionIndexOrNone(copySectionIndex, len(copySections)))...)
				} else {
					rendered = appendWrappedDetailLines(rendered, " "+heading, width, m.theme.DetailH1)
				}
				continue
			}
			rendered = appendWrappedDetailLines(rendered, " "+heading, width, m.theme.DetailH1)
		case strings.HasPrefix(trimmed, "## "):
			heading := strings.TrimPrefix(trimmed, "## ")
			if _, ok := normalizedSectionHeading(heading); ok {
				if showCopyButtons {
					copySectionIndex++
					rendered = append(rendered, m.renderCopyableHeadingLine(heading, width, sectionIndexOrNone(copySectionIndex, len(copySections)))...)
				} else {
					rendered = appendWrappedDetailLines(rendered, " "+heading, width, m.theme.DetailH2)
				}
				continue
			}
			rendered = appendWrappedDetailLines(rendered, " "+heading, width, m.theme.DetailH2)
		case strings.HasPrefix(trimmed, "### "):
			heading := strings.TrimPrefix(trimmed, "### ")
			if _, ok := normalizedSectionHeading(heading); ok {
				if showCopyButtons {
					copySectionIndex++
					rendered = append(rendered, m.renderCopyableHeadingLine(heading, width, sectionIndexOrNone(copySectionIndex, len(copySections)))...)
				} else {
					rendered = appendWrappedDetailLines(rendered, " "+heading, width, m.theme.DetailH3)
				}
				continue
			}
			rendered = appendWrappedDetailLines(rendered, " "+heading, width, m.theme.DetailH3)
		case strings.HasPrefix(trimmed, "- ") || strings.HasPrefix(trimmed, "* ") || strings.HasPrefix(trimmed, "+ "):
			content := strings.TrimPrefix(strings.TrimPrefix(strings.TrimPrefix(trimmed, "- "), "* "), "+ ")
			rendered = appendWrappedDetailLines(rendered, " • "+content, width, m.theme.DetailList)
		case terminalCommands:
			rendered = appendCommandLines(rendered, trimmed, width, m.theme)
		default:
			if _, ok := normalizedSectionHeading(trimmed); ok {
				if showCopyButtons {
					copySectionIndex++
					rendered = append(rendered, m.renderCopyableHeadingLine(trimmed, width, sectionIndexOrNone(copySectionIndex, len(copySections)))...)
				} else {
					rendered = appendWrappedDetailLines(rendered, " "+trimmed, width, m.theme.DetailH2)
				}
				continue
			}
			rendered = appendWrappedDetailLines(rendered, " "+line, width, m.theme.DetailPlain)
		}
	}

	return rendered
}

func sectionIndexOrNone(index, total int) int {
	if index < 0 || index >= total {
		return -1
	}
	return index
}

func normalizedSectionHeading(line string) (string, bool) {
	trimmed := strings.TrimSpace(strings.TrimLeft(strings.TrimSpace(line), "#"))
	if !sectionTitlePattern.MatchString(trimmed) {
		return "", false
	}
	return trimmed, true
}

func (m model) renderCopyableHeadingLine(heading string, width int, copySection int) []detailRenderedLine {
	button := m.theme.RenderCopyButton()
	buttonWidth := lipgloss.Width(button)
	textWidth := max(width-buttonWidth-3, 12)
	title := truncateLine(heading, textWidth)
	line := m.theme.DetailH2.Render(" "+title) + " " + button
	return []detailRenderedLine{{text: line, copySection: copySection}}
}

func appendCommandLines(dst []detailRenderedLine, line string, width int, theme Theme) []detailRenderedLine {
	trimmed := strings.TrimSpace(line)
	if trimmed == "" {
		return append(dst, detailRenderedLine{text: "", copySection: -1})
	}
	if strings.HasPrefix(trimmed, "#") {
		return appendWrappedDetailLines(dst, " "+trimmed, width, theme.DetailMeta)
	}
	command := strings.TrimPrefix(trimmed, "$ ")
	return appendWrappedDetailLines(dst, " $ "+command, width, theme.DetailCommand)
}

func appendWrappedDetailLines(dst []detailRenderedLine, line string, width int, style lipgloss.Style) []detailRenderedLine {
	if strings.TrimSpace(line) == "" {
		return append(dst, detailRenderedLine{text: "", copySection: -1})
	}
	if width < 12 {
		width = 12
	}
	for _, part := range wrapLine(line, width) {
		dst = append(dst, detailRenderedLine{text: style.Render(part), copySection: -1})
	}
	return dst
}

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

func truncateLine(text string, width int) string {
	if width < 1 {
		return ""
	}
	runes := []rune(text)
	if len(runes) <= width {
		return text
	}
	if width == 1 {
		return "…"
	}
	candidate := string(runes[:width-1])
	if cut := strings.LastIndexFunc(candidate, unicode.IsSpace); cut > width/2 {
		candidate = strings.TrimRightFunc(candidate[:cut], unicode.IsSpace)
	}
	return candidate + "…"
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
