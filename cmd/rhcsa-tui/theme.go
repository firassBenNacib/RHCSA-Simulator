package main

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

type Theme struct {
	TabBar              lipgloss.Style
	TabActive           lipgloss.Style
	TabInactive         lipgloss.Style
	TabBorder           lipgloss.Style
	ViewMode            lipgloss.Style
	ViewModeActive      lipgloss.Style
	CopyButton          lipgloss.Style
	ListPane            lipgloss.Style
	DetailPane          lipgloss.Style
	PaneBorder          lipgloss.Style
	PaneHeader          lipgloss.Style
	PaneHeaderFocused   lipgloss.Style
	PaneTitle           lipgloss.Style
	PaneSubtitle        lipgloss.Style
	ItemSelected        lipgloss.Style
	ItemSelectedBlurred lipgloss.Style
	ItemNormal          lipgloss.Style
	ItemRunning         lipgloss.Style
	ItemCursor          lipgloss.Style
	BadgePassed         lipgloss.Style
	BadgeChecked        lipgloss.Style
	BadgeStarted        lipgloss.Style
	BadgeViewed         lipgloss.Style
	BadgeEmpty          lipgloss.Style
	DetailH1            lipgloss.Style
	DetailH2            lipgloss.Style
	DetailH3            lipgloss.Style
	DetailMeta          lipgloss.Style
	DetailCode          lipgloss.Style
	DetailCommand       lipgloss.Style
	DetailList          lipgloss.Style
	DetailPlain         lipgloss.Style
	DetailRule          lipgloss.Style
	ActiveBadge         lipgloss.Style
	OutputPanel         lipgloss.Style
	OutputTitle         lipgloss.Style
	OutputError         lipgloss.Style
	OutputWarning       lipgloss.Style
	OutputSuccess       lipgloss.Style
	OutputInfo          lipgloss.Style
	OutputMuted         lipgloss.Style
	SearchLabel         lipgloss.Style
	SearchInput         lipgloss.Style
	ScrollIndicator     lipgloss.Style
	FooterBar           lipgloss.Style
	FooterKey           lipgloss.Style
	FooterValue         lipgloss.Style
	Overlay             lipgloss.Style
	HelpCloseBtn        lipgloss.Style
	Muted               lipgloss.Style
	Dim                 lipgloss.Style
}

func NewTheme() Theme {
	red := lipgloss.Color("#DC2626")
	redLight := lipgloss.Color("#F87171")
	redMuted := lipgloss.Color("#4A171B")

	bgDark := lipgloss.Color("#090E17")
	bgMid := lipgloss.Color("#0F1724")
	bgCard := lipgloss.Color("#151E2D")
	border := lipgloss.Color("#334155")
	borderSoft := lipgloss.Color("#243244")

	textBright := lipgloss.Color("#f9fafb")
	textNormal := lipgloss.Color("#e5e7eb")
	textDim := lipgloss.Color("#d1d5db")
	textMuted := lipgloss.Color("#9ca3af")
	textFaint := lipgloss.Color("#6b7280")
	textDimmer := lipgloss.Color("#4b5563")

	green := lipgloss.Color("#10b981")
	blue := lipgloss.Color("#3b82f6")
	yellow := lipgloss.Color("#fbbf24")
	orange := lipgloss.Color("#fb923c")
	codeGreen := lipgloss.Color("#7FE9D0")
	codeBlue := lipgloss.Color("#93C5FD")

	return Theme{
		TabBar: lipgloss.NewStyle().
			Padding(0, 2),
		TabActive: lipgloss.NewStyle().
			Padding(0, 2).
			Bold(true).
			Foreground(textBright).
			Background(redMuted),
		TabInactive: lipgloss.NewStyle().
			Padding(0, 2).
			Foreground(textMuted),
		TabBorder: lipgloss.NewStyle().
			Foreground(borderSoft),
		ViewMode: lipgloss.NewStyle().
			Padding(0, 2).
			Foreground(textMuted),
		ViewModeActive: lipgloss.NewStyle().
			Padding(0, 2).
			Bold(true).
			Foreground(textBright).
			Background(redMuted),
		CopyButton: lipgloss.NewStyle().
			Padding(0, 2).
			Bold(true).
			Foreground(textBright).
			Background(redMuted),
		ListPane: lipgloss.NewStyle().
			Align(lipgloss.Left),
		DetailPane: lipgloss.NewStyle().
			Align(lipgloss.Left),
		PaneBorder: lipgloss.NewStyle().
			Foreground(borderSoft),
		PaneHeader: lipgloss.NewStyle().
			Foreground(textMuted),
		PaneHeaderFocused: lipgloss.NewStyle().
			Foreground(textNormal),
		PaneTitle: lipgloss.NewStyle().
			Foreground(textBright).
			Bold(true),
		PaneSubtitle: lipgloss.NewStyle().
			Foreground(textMuted),
		ItemSelected: lipgloss.NewStyle().
			Foreground(textBright).
			Background(redMuted).
			Bold(true),
		ItemSelectedBlurred: lipgloss.NewStyle().
			Foreground(textNormal).
			Background(bgCard),
		ItemNormal: lipgloss.NewStyle().
			Foreground(textDim),
		ItemRunning: lipgloss.NewStyle().
			Foreground(yellow),
		ItemCursor: lipgloss.NewStyle().
			Foreground(red).
			Bold(true),
		BadgePassed: lipgloss.NewStyle().
			Foreground(bgDark).
			Background(green).
			Padding(0, 1).
			Bold(true),
		BadgeChecked: lipgloss.NewStyle().
			Foreground(bgDark).
			Background(blue).
			Padding(0, 1).
			Bold(true),
		BadgeStarted: lipgloss.NewStyle().
			Foreground(bgDark).
			Background(yellow).
			Padding(0, 1).
			Bold(true),
		BadgeViewed: lipgloss.NewStyle().
			Foreground(textNormal).
			Padding(0, 1),
		BadgeEmpty: lipgloss.NewStyle().
			Foreground(textDimmer).
			Padding(0, 1),
		DetailH1: lipgloss.NewStyle().
			Foreground(textBright),
		DetailH2: lipgloss.NewStyle().
			Foreground(redLight).
			Bold(true),
		DetailH3: lipgloss.NewStyle().
			Foreground(orange),
		DetailMeta: lipgloss.NewStyle().
			Foreground(textMuted),
		DetailCode: lipgloss.NewStyle().
			Foreground(codeBlue),
		DetailCommand: lipgloss.NewStyle().
			Foreground(codeGreen).
			Bold(true),
		DetailList: lipgloss.NewStyle().
			Foreground(textDim),
		DetailPlain: lipgloss.NewStyle().
			Foreground(textNormal),
		DetailRule: lipgloss.NewStyle().
			Foreground(border),
		ActiveBadge: lipgloss.NewStyle().
			Foreground(textBright).
			Background(redMuted).
			Padding(0, 1).
			Bold(true),
		OutputPanel: lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(borderSoft).
			Padding(0, 1).
			Background(bgDark),
		OutputTitle: lipgloss.NewStyle().
			Foreground(red).
			Bold(true),
		OutputError:   lipgloss.NewStyle().Foreground(lipgloss.Color("#ef4444")),
		OutputWarning: lipgloss.NewStyle().Foreground(lipgloss.Color("#f59e0b")),
		OutputSuccess: lipgloss.NewStyle().Foreground(green),
		OutputInfo:    lipgloss.NewStyle().Foreground(textNormal),
		OutputMuted:   lipgloss.NewStyle().Foreground(textFaint),
		SearchLabel: lipgloss.NewStyle().
			Foreground(red).
			Bold(true),
		SearchInput: lipgloss.NewStyle().
			Foreground(textBright).
			Background(bgCard).
			Padding(0, 1),
		ScrollIndicator: lipgloss.NewStyle().
			Foreground(textFaint),
		FooterBar: lipgloss.NewStyle().
			Border(lipgloss.NormalBorder(), true, false, false, false).
			BorderForeground(borderSoft).
			Padding(0, 1),
		FooterKey: lipgloss.NewStyle().
			Foreground(red).
			Bold(true),
		FooterValue: lipgloss.NewStyle().
			Foreground(textNormal),
		Overlay: lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(red).
			Padding(1, 3).
			Foreground(textNormal).
			Background(bgMid),
		HelpCloseBtn: lipgloss.NewStyle().
			Padding(0, 1).
			Foreground(textBright).
			Background(red).
			Bold(true),
		Muted: lipgloss.NewStyle().
			Foreground(textFaint),
		Dim: lipgloss.NewStyle().
			Foreground(textDimmer),
	}
}
func (t Theme) RenderTabs(activeTab tabName, width int) string {
	labsStr := t.TabInactive.Render("LABS")
	examsStr := t.TabInactive.Render("EXAMS")

	if activeTab == labsTab {
		labsStr = t.TabActive.Render("LABS")
	} else {
		examsStr = t.TabActive.Render("EXAMS")
	}

	tabs := lipgloss.JoinHorizontal(lipgloss.Left, labsStr, "   ", examsStr)
	bar := t.TabBar.Width(width).Render(tabs)
	rule := t.TabBorder.Render(strings.Repeat("─", width))
	return bar + "\n" + rule
}
func (t Theme) RenderViewModes(active detailMode, isExam bool) string {
	type modeEntry struct {
		mode  detailMode
		label string
	}

	var modes []modeEntry
	if isExam {
		modes = []modeEntry{
			{detailPrompt, "TASKS"},
			{detailSolution, "SOLUTIONS"},
		}
	} else {
		modes = []modeEntry{
			{detailPrompt, "TASKS"},
			{detailHint, "HINTS"},
			{detailCheck, "CHECKS"},
			{detailSolution, "SOLUTIONS"},
		}
	}

	parts := make([]string, 0, len(modes))
	for _, m := range modes {
		if m.mode == active {
			parts = append(parts, t.ViewModeActive.Render(m.label))
		} else {
			parts = append(parts, t.ViewMode.Render(m.label))
		}
	}

	return lipgloss.JoinHorizontal(lipgloss.Left, parts...)
}

func (t Theme) RenderCopyButton() string {
	return t.CopyButton.Render("[COPY]")
}
func (t Theme) StatusBadge(marker string) string {
	switch marker {
	case "P":
		return t.BadgePassed.Render("PASSED")
	case "C":
		return t.BadgeChecked.Render("CHECKED")
	case "S":
		return t.BadgeStarted.Render("RUNNING")
	default:
		return ""
	}
}
