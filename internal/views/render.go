package views

import (
	"regexp"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

type Theme struct {
	Title         lipgloss.Style
	Subtitle      lipgloss.Style
	Tab           lipgloss.Style
	ActiveTab     lipgloss.Style
	Pane          lipgloss.Style
	ActivePane    lipgloss.Style
	Footer        lipgloss.Style
	Selected      lipgloss.Style
	Running       lipgloss.Style
	Muted         lipgloss.Style
	Overlay       lipgloss.Style
	DetailMeta    lipgloss.Style
	DetailH1      lipgloss.Style
	DetailH2      lipgloss.Style
	DetailH3      lipgloss.Style
	DetailRule    lipgloss.Style
	DetailList    lipgloss.Style
	DetailCode    lipgloss.Style
	OutputError   lipgloss.Style
	OutputWarning lipgloss.Style
	OutputSuccess lipgloss.Style
	OutputInfo    lipgloss.Style
	OutputMuted   lipgloss.Style
}

func NewTheme() Theme {
	return Theme{
		Title:         lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("196")),
		Subtitle:      lipgloss.NewStyle().Foreground(lipgloss.Color("246")),
		Tab:           lipgloss.NewStyle().Padding(0, 1).Foreground(lipgloss.Color("248")).BorderForeground(lipgloss.Color("238")),
		ActiveTab:     lipgloss.NewStyle().Padding(0, 1).Bold(true).Foreground(lipgloss.Color("255")).Background(lipgloss.Color("160")),
		Pane:          lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(lipgloss.Color("238")).Padding(0, 1),
		ActivePane:    lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(lipgloss.Color("160")).Padding(0, 1),
		Footer:        lipgloss.NewStyle().Foreground(lipgloss.Color("245")),
		Selected:      lipgloss.NewStyle().Foreground(lipgloss.Color("203")).Bold(true),
		Running:       lipgloss.NewStyle().Foreground(lipgloss.Color("203")).Bold(true),
		Muted:         lipgloss.NewStyle().Foreground(lipgloss.Color("245")),
		Overlay:       lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(lipgloss.Color("160")).Padding(1, 2).Foreground(lipgloss.Color("255")).Background(lipgloss.Color("234")).Width(72),
		DetailMeta:    lipgloss.NewStyle().Foreground(lipgloss.Color("217")).Bold(true),
		DetailH1:      lipgloss.NewStyle().Foreground(lipgloss.Color("203")).Bold(true),
		DetailH2:      lipgloss.NewStyle().Foreground(lipgloss.Color("210")).Bold(true),
		DetailH3:      lipgloss.NewStyle().Foreground(lipgloss.Color("216")).Bold(true),
		DetailRule:    lipgloss.NewStyle().Foreground(lipgloss.Color("160")),
		DetailList:    lipgloss.NewStyle().Foreground(lipgloss.Color("252")),
		DetailCode:    lipgloss.NewStyle().Foreground(lipgloss.Color("250")),
		OutputError:   lipgloss.NewStyle().Foreground(lipgloss.Color("203")).Bold(true),
		OutputWarning: lipgloss.NewStyle().Foreground(lipgloss.Color("214")).Bold(true),
		OutputSuccess: lipgloss.NewStyle().Foreground(lipgloss.Color("114")).Bold(true),
		OutputInfo:    lipgloss.NewStyle().Foreground(lipgloss.Color("117")),
		OutputMuted:   lipgloss.NewStyle().Foreground(lipgloss.Color("245")),
	}
}

func (t Theme) RenderTabs(labels []string, active int) string {
	parts := make([]string, 0, len(labels))
	for index, label := range labels {
		style := t.Tab
		if index == active {
			style = t.ActiveTab
		}
		parts = append(parts, style.Render(label))
	}

	return strings.Join(parts, "  ")
}

func (t Theme) RenderPane(title, body string, width, height int, active bool) string {
	if width < 8 {
		width = 8
	}
	if height < 4 {
		height = 4
	}

	border := lipgloss.RoundedBorder()
	borderColor := lipgloss.Color("238")
	if active {
		borderColor = lipgloss.Color("160")
	}
	borderStyle := lipgloss.NewStyle().Foreground(borderColor)

	textWidth := max(width-4, 1)
	contentHeight := max(height-2, 1)
	lines := []string{title, ""}
	if body != "" {
		lines = append(lines, strings.Split(body, "\n")...)
	}
	if len(lines) > contentHeight {
		lines = lines[:contentHeight]
	}
	for len(lines) < contentHeight {
		lines = append(lines, "")
	}

	rendered := make([]string, 0, height)
	rendered = append(rendered, borderStyle.Render(border.TopLeft+strings.Repeat(border.Top, width-2)+border.TopRight))
	for _, line := range lines {
		display := fitStyledLine(line, textWidth)
		padding := strings.Repeat(" ", max(textWidth-lipgloss.Width(display), 0))
		rendered = append(rendered,
			borderStyle.Render(border.Left)+" "+display+padding+" "+borderStyle.Render(border.Right),
		)
	}
	rendered = append(rendered, borderStyle.Render(border.BottomLeft+strings.Repeat(border.Bottom, width-2)+border.BottomRight))

	return strings.Join(rendered, "\n")
}

func (t Theme) RenderFooter(text string, width int) string {
	return t.Footer.Width(width).Render(text)
}

var paneAnsiPattern = regexp.MustCompile(`\x1b\[[0-9;?]*[ -/]*[@-~]`)

func fitStyledLine(text string, width int) string {
	if width < 1 {
		return ""
	}
	if lipgloss.Width(text) <= width {
		return text
	}

	plain := paneAnsiPattern.ReplaceAllString(text, "")
	runes := []rune(plain)
	if len(runes) <= width {
		return plain
	}
	return string(runes[:width])
}

func max(left, right int) int {
	if left > right {
		return left
	}
	return right
}
