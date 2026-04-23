package main

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

func matchesDetailModeKey(mode detailMode, msg tea.KeyMsg) bool {
	switch mode {
	case detailPrompt:
		switch msg.String() {
		case "1", "kp1", "f1", "&":
			return true
		}
	case detailHint:
		normalized := normalizeTerminalText(msg.String())
		switch normalized {
		case "2", "kp2", "f2":
			return true
		}
		return strings.Contains(normalized, "é") || strings.Contains(normalized, "É")
	case detailCheck:
		switch msg.String() {
		case "3", "kp3", "f3", "\"":
			return true
		}
	case detailSolution:
		switch msg.String() {
		case "4", "kp4", "f4", "'", "\u2019":
			return true
		}
	}
	return false
}

func matchesPromptViewKey(msg tea.KeyMsg) bool   { return matchesDetailModeKey(detailPrompt, msg) }
func matchesHintViewKey(msg tea.KeyMsg) bool     { return matchesDetailModeKey(detailHint, msg) }
func matchesCheckViewKey(msg tea.KeyMsg) bool    { return matchesDetailModeKey(detailCheck, msg) }
func matchesSolutionViewKey(msg tea.KeyMsg) bool { return matchesDetailModeKey(detailSolution, msg) }

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
