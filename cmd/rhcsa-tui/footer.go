package main

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

type footerActionID int

const (
	footerActionStart footerActionID = iota
	footerActionReset
	footerActionPane
	footerActionSwitch
	footerActionCheck
	footerActionTasks
	footerActionHints
	footerActionChecks
	footerActionSolutions
	footerActionFind
	footerActionHelp
	footerActionQuit
	footerActionFilterKeep
	footerActionFilterClear
	footerActionSSHClient
	footerActionSSHServer
)

type footerAction struct {
	key   string
	label string
	id    footerActionID
}

type footerActionBound struct {
	id     footerActionID
	startX int
	endX   int
	y      int
}

func (m model) footerActions() []footerAction {
	var actions []footerAction
	if m.filterMode {
		return []footerAction{
			{"Enter", "Keep", footerActionFilterKeep},
			{"Esc", "Clear", footerActionFilterClear},
		}
	}

	actions = []footerAction{
		{"Enter", "Start", footerActionStart},
		{"r", "Reset", footerActionReset},
		{"Tab", "Pane", footerActionPane},
	}
	arrowLabel := "L/E"
	if m.focus == focusDetail {
		arrowLabel = "Docs"
	}
	actions = append(actions, footerAction{"←→", arrowLabel, footerActionSwitch})
	if m.activeTab == labsTab {
		actions = append(actions, footerAction{"c", "Check", footerActionCheck})
		actions = append(actions,
			footerAction{"F1", "Tasks", footerActionTasks},
			footerAction{"F2", "Hints", footerActionHints},
			footerAction{"F3", "Checks", footerActionChecks},
			footerAction{"F4", "Solutions", footerActionSolutions},
		)
	} else {
		actions = append(actions,
			footerAction{"F1", "Tasks", footerActionTasks},
			footerAction{"F4", "Solutions", footerActionSolutions},
		)
	}
	actions = append(actions,
		footerAction{"z", "Client", footerActionSSHClient},
		footerAction{"x", "Server", footerActionSSHServer},
		footerAction{"/", "Find", footerActionFind},
		footerAction{"?", "Help", footerActionHelp},
		footerAction{"q", "Quit", footerActionQuit},
	)
	return actions
}

func (m model) visibleFooterActions(width int) []footerAction {
	actions := m.footerActions()
	parts := make([]string, 0, len(actions))
	usedWidth := 0
	for i, action := range actions {
		part := m.theme.FooterKey.Render(action.key) + m.theme.FooterValue.Render(" "+action.label)
		partWidth := lipgloss.Width(part)
		if i > 0 {
			partWidth += 2
		}
		if usedWidth+partWidth > width-2 {
			break
		}
		parts = append(parts, part)
		usedWidth += partWidth
	}
	return actions[:len(parts)]
}

func (m model) renderFooter(width int) string {
	actions := m.visibleFooterActions(width)
	parts := make([]string, 0, len(actions))
	for _, action := range actions {
		parts = append(parts, m.theme.FooterKey.Render(action.key)+m.theme.FooterValue.Render(" "+action.label))
	}

	return m.theme.FooterBar.Width(width).Render(strings.Join(parts, "  "))
}

func (m model) footerActionBounds(width int) []footerActionBound {
	actions := m.visibleFooterActions(width)
	bounds := make([]footerActionBound, 0, len(actions))

	rendered := StripAnsi(m.renderFooter(width))
	lines := strings.Split(rendered, "\n")
	if len(lines) == 0 {
		return bounds
	}
	content := lines[len(lines)-1]
	searchFrom := 0
	for _, action := range actions {
		target := action.key + " " + action.label
		idx := strings.Index(content[searchFrom:], target)
		if idx < 0 {
			continue
		}
		startByte := searchFrom + idx
		startX := lipgloss.Width(content[:startByte])
		targetWidth := lipgloss.Width(target)
		bounds = append(bounds, footerActionBound{
			id:     action.id,
			startX: startX,
			endX:   startX + targetWidth - 1,
			y:      m.height - 1,
		})
		searchFrom = startByte + len(target)
	}
	return bounds
}

func (m model) helpCloseBtnBounds() (startX, endX, y int, ok bool) {
	if !m.showHelp {
		return 0, 0, 0, false
	}
	view := StripAnsi(m.View())
	lines := strings.Split(view, "\n")
	for row, line := range lines {
		idx := strings.Index(line, helpCloseBtn)
		if idx < 0 {
			continue
		}
		prefix := line[:idx]
		if strings.TrimSpace(prefix) == "" {
			continue
		}
		startX = lipgloss.Width(prefix)
		endX = startX + lipgloss.Width(helpCloseBtn) - 1
		return startX, endX, row, true
	}
	return 0, 0, 0, false
}

func (m model) renderHelpWithClose() string {
	body := m.helpBody()
	lines := strings.Split(body, "\n")
	if len(lines) == 0 {
		return body
	}
	maxWidth := 0
	for _, l := range lines {
		w := lipgloss.Width(l)
		if w > maxWidth {
			maxWidth = w
		}
	}
	maxWidth = max(maxWidth, 52)
	btn := m.theme.HelpCloseBtn.Render(helpCloseBtn)
	btnWidth := lipgloss.Width(btn)
	if maxWidth < btnWidth+2 {
		maxWidth = btnWidth + 2
	}
	lines[0] = m.fillLine(lines[0], btn, maxWidth)
	return strings.Join(lines, "\n")
}

type sectionCopyBound struct {
	section int
	startX  int
	endX    int
	lineX   int
	lineEnd int
	y       int
}

func (b sectionCopyBound) contains(x int) bool {
	return hitHorizontalBound(x, b.startX, b.endX) || hitHorizontalBound(x, b.lineX, b.lineEnd)
}

func (m model) detailSectionCopyBounds() []sectionCopyBound {
	if !m.canCopyDetail() {
		return nil
	}

	bodyLines := m.renderDetailBodyLines(m.detailTextWidth())
	if len(bodyLines) == 0 {
		return nil
	}

	offset := m.currentDetailOffset()
	if offset > len(bodyLines) {
		offset = len(bodyLines)
	}
	visible := bodyLines[offset:]
	bodyHeight := max(m.detailPaneHeight()-len(m.renderDetailHeaderLines(m.detailPaneWidth())), 1)
	if len(visible) > bodyHeight {
		visible = visible[:bodyHeight]
	}

	originX, originY := m.detailPaneOrigin()
	headerHeight := len(m.renderDetailHeaderLines(m.detailPaneWidth()))
	bounds := make([]sectionCopyBound, 0, 8)
	button := StripAnsi(m.theme.RenderCopyButton())
	buttonLabel := "[COPY]"
	leftPad := strings.Index(button, buttonLabel)
	if leftPad < 0 {
		leftPad = 0
	}
	for i, line := range visible {
		if line.copySection < 0 {
			continue
		}
		stripped := StripAnsi(line.text)
		idx := strings.LastIndex(stripped, button)
		target := button
		if idx < 0 {
			idx = strings.LastIndex(stripped, buttonLabel)
			target = buttonLabel
			if idx < 0 {
				continue
			}
		}
		startX := originX + lipgloss.Width(stripped[:idx])
		if target == buttonLabel {
			startX -= leftPad
		}
		if startX < originX {
			startX = originX
		}
		buttonWidth := lipgloss.Width(target)
		if target == buttonLabel {
			buttonWidth += leftPad
		}
		bounds = append(bounds, sectionCopyBound{
			section: line.copySection,
			startX:  startX,
			endX:    startX + buttonWidth - 1,
			lineX:   originX,
			lineEnd: originX + lipgloss.Width(stripped) - 1,
			y:       originY + headerHeight + i,
		})
	}

	return bounds
}
