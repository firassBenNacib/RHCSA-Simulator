package main

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// Theme holds every style the TUI uses, organised by region.
type Theme struct {
	// Header bar
	HeaderBar  lipgloss.Style
	AppName    lipgloss.Style
	AppVersion lipgloss.Style

	// Tab bar
	TabBar      lipgloss.Style
	TabActive   lipgloss.Style
	TabInactive lipgloss.Style
	TabBorder   lipgloss.Style

	// View mode (TASKS / HINTS / SOLUTIONS / CHECKS)
	ViewMode       lipgloss.Style
	ViewModeActive lipgloss.Style
	CopyButton     lipgloss.Style

	// Pane chrome
	ListPane          lipgloss.Style
	DetailPane        lipgloss.Style
	PaneBorder        lipgloss.Style
	PaneHeader        lipgloss.Style
	PaneHeaderFocused lipgloss.Style
	PaneTitle         lipgloss.Style
	PaneSubtitle      lipgloss.Style

	// List items
	ItemSelected        lipgloss.Style
	ItemSelectedBlurred lipgloss.Style
	ItemNormal          lipgloss.Style
	ItemRunning         lipgloss.Style
	ItemCursor          lipgloss.Style

	// Progress badges
	BadgePassed  lipgloss.Style
	BadgeChecked lipgloss.Style
	BadgeStarted lipgloss.Style
	BadgeViewed  lipgloss.Style
	BadgeEmpty   lipgloss.Style

	// Detail content
	DetailH1      lipgloss.Style
	DetailH2      lipgloss.Style
	DetailH3      lipgloss.Style
	DetailMeta    lipgloss.Style
	DetailCode    lipgloss.Style
	DetailCommand lipgloss.Style
	DetailList    lipgloss.Style
	DetailPlain   lipgloss.Style
	DetailRule    lipgloss.Style

	// Active badge shown in detail header
	ActiveBadge lipgloss.Style

	// Output / status panel
	OutputPanel   lipgloss.Style
	OutputTitle   lipgloss.Style
	OutputError   lipgloss.Style
	OutputWarning lipgloss.Style
	OutputSuccess lipgloss.Style
	OutputInfo    lipgloss.Style
	OutputMuted   lipgloss.Style

	// Search input
	SearchLabel lipgloss.Style
	SearchInput lipgloss.Style

	// Scroll indicators
	ScrollIndicator lipgloss.Style

	// Footer
	FooterBar   lipgloss.Style
	FooterKey   lipgloss.Style
	FooterValue lipgloss.Style

	// Utility
	Overlay lipgloss.Style
	Muted   lipgloss.Style
	Dim     lipgloss.Style
}

// NewTheme builds the default RHCSA terminal theme.
func NewTheme() Theme {
	red := lipgloss.Color("#DC2626")
	redLight := lipgloss.Color("#F87171")
	redMuted := lipgloss.Color("#3F1417")

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
	codeGreen := lipgloss.Color("#6ee7b7")

	return Theme{
		// ── Header bar ──────────────────────────────────────
		HeaderBar: lipgloss.NewStyle().
			Padding(0, 2),
		AppName: lipgloss.NewStyle().
			Bold(true).
			Foreground(red),
		AppVersion: lipgloss.NewStyle().
			Foreground(textMuted),

		// ── Tab bar ─────────────────────────────────────────
		TabBar: lipgloss.NewStyle().
			Padding(0, 2),
		TabActive: lipgloss.NewStyle().
			Padding(0, 1).
			Bold(true).
			Foreground(redLight),
		TabInactive: lipgloss.NewStyle().
			Padding(0, 1).
			Foreground(textMuted),
		TabBorder: lipgloss.NewStyle().
			Foreground(borderSoft),

		// ── View mode bar ───────────────────────────────────
		ViewMode: lipgloss.NewStyle().
			Padding(0, 1).
			Foreground(textMuted),
		ViewModeActive: lipgloss.NewStyle().
			Padding(0, 1).
			Bold(true).
			Foreground(redLight),
		CopyButton: lipgloss.NewStyle().
			Padding(0, 1).
			Bold(true).
			Foreground(textBright).
			Background(bgCard),

		// ── Panes ───────────────────────────────────────────
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

		// ── List items ──────────────────────────────────────
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

		// ── Badges ──────────────────────────────────────────
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

		// ── Detail content ──────────────────────────────────
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
			Foreground(codeGreen).
			Background(bgCard).
			Padding(0, 1),
		DetailCommand: lipgloss.NewStyle().
			Foreground(codeGreen).
			Background(bgCard).
			Padding(0, 1),
		DetailList: lipgloss.NewStyle().
			Foreground(textDim),
		DetailPlain: lipgloss.NewStyle().
			Foreground(textNormal),
		DetailRule: lipgloss.NewStyle().
			Foreground(border),

		// ── Active badge ────────────────────────────────────
		ActiveBadge: lipgloss.NewStyle().
			Foreground(bgDark).
			Background(green).
			Padding(0, 1).
			Bold(true),

		// ── Output panel ────────────────────────────────────
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

		// ── Search ──────────────────────────────────────────
		SearchLabel: lipgloss.NewStyle().
			Foreground(red).
			Bold(true),
		SearchInput: lipgloss.NewStyle().
			Foreground(textBright).
			Background(bgCard).
			Padding(0, 1),

		// ── Scroll indicators ───────────────────────────────
		ScrollIndicator: lipgloss.NewStyle().
			Foreground(textFaint),

		// ── Footer ──────────────────────────────────────────
		FooterBar: lipgloss.NewStyle().
			Border(lipgloss.NormalBorder(), true, false, false, false).
			BorderForeground(borderSoft).
			Padding(0, 1),
		FooterKey: lipgloss.NewStyle().
			Foreground(red).
			Bold(true),
		FooterValue: lipgloss.NewStyle().
			Foreground(textNormal),

		// ── Utility ─────────────────────────────────────────
		Overlay: lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(red).
			Padding(2, 3).
			Foreground(textNormal).
			Background(bgMid),
		Muted: lipgloss.NewStyle().
			Foreground(textFaint),
		Dim: lipgloss.NewStyle().
			Foreground(textDimmer),
	}
}

// ── Rendering helpers ───────────────────────────────────────

// RenderHeader returns the top header bar with app name and version.
func (t Theme) RenderHeader(width int) string {
	name := t.AppName.Render("RHCSA Simulator")
	ver := t.AppVersion.Render(" v" + version)
	content := name + ver
	return t.HeaderBar.Width(width).Render(content)
}

// RenderTabs renders the LABS / EXAMS tab bar.
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
	rule := t.TabBorder.Width(width).Render(strings.Repeat("─", width))
	return bar + "\n" + rule
}

// RenderViewModes renders the TASKS / HINTS / SOLUTIONS / CHECKS tabs.
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

// StatusBadge returns a styled single-char badge for the given progress marker.
func (t Theme) StatusBadge(marker string) string {
	switch marker {
	case "P":
		return t.BadgePassed.Render("Passed")
	case "C":
		return t.BadgeChecked.Render("Checked")
	case "S":
		return t.BadgeStarted.Render("Started")
	default:
		return ""
	}
}
