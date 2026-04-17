package main

import (
	"fmt"
	"strings"
	"unicode"

	tea "github.com/charmbracelet/bubbletea"

	"rhcsa_exam_vms/internal/backend"
)

func normalizeUnicode(s string) string {
	runes := []rune(s)
	result := make([]rune, 0, len(runes))
	for _, r := range runes {
		if unicode.IsControl(r) && r != '\n' && r != '\t' && r != '\r' {
			continue
		}
		result = append(result, r)
	}
	return string(result)
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = int(msg.Width)
		m.height = int(msg.Height)
		return m, nil
		
	case tea.MouseMsg:
		return m.handleMouse(msg)
		
	case actionResultMsg:
		return m.handleActionResult(msg)
	case tea.KeyMsg:
		return m.handleKeyMsg(msg)
	}

	return m, nil
}

func (m model) handleMouse(msg tea.MouseMsg) (tea.Model, tea.Cmd) {
	// Mouse support disabled for stability - use keyboard navigation
	return m, nil
}

func (m model) itemCount() int {
	if m.activeTab == labsTab {
		return len(m.filteredLabs())
	}
	return len(m.filteredExams())
}

func (m model) handleActionResult(msg actionResultMsg) (tea.Model, tea.Cmd) {
	m.busy = false
	if msg.err != nil {
		m.statusText = summarizeActionOutput(msg.output)
		if m.statusText == "" {
			m.statusText = msg.err.Error()
		}
	} else {
		m.statusText = summarizeActionOutput(msg.output)
		if msg.kind == "start-lab" {
			m.refreshActiveScenarioID()
			m.progress.TouchStarted(msg.labID)
			if err := m.progress.Save(m.progressPath); err != nil {
				m.statusText += "\nWarning: Failed to save progress: " + err.Error()
			}
		}
		if msg.kind == "start-exam" {
			m.refreshActiveScenarioID()
			m.progress.TouchExamStarted(msg.labID)
			if err := m.progress.Save(m.progressPath); err != nil {
				m.statusText += "\nWarning: Failed to save progress: " + err.Error()
			}
		}
		if msg.kind == "check-lab" {
			m.progress.TouchChecked(msg.labID, msg.passed)
			if err := m.progress.Save(m.progressPath); err != nil {
				m.statusText += "\nWarning: Failed to save progress: " + err.Error()
			}
		}
	}
	return m, nil
}

func (m model) handleKeyMsg(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.filterMode {
		return m.handleFilterKey(msg)
	}

	if m.showHelp {
		return m.handleHelpKey(msg)
	}

	if m.busy {
		return m.handleBusyKey(msg)
	}

	if m.confirmKind != "" {
		return m.handleConfirmKey(msg)
	}

	return m.handleNormalKey(msg)
}

func (m model) handleFilterKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if text, ok := filterTextForKey(msg); ok {
		m.filterQuery += text
		m.normalizeSelection()
		m.adjustListOffset()
		return m, nil
	}
	switch msg.Type {
	case tea.KeyEsc:
		if m.filterQuery != "" {
			m.filterQuery = ""
			m.normalizeSelection()
			m.adjustListOffset()
		}
		m.filterMode = false
		m.statusText = ""
		return m, nil
	case tea.KeyEnter:
		m.filterMode = false
		m.statusText = ""
		return m, nil
	case tea.KeyBackspace, tea.KeyDelete:
		if len(m.filterQuery) > 0 {
			runes := []rune(m.filterQuery)
			m.filterQuery = string(runes[:len(runes)-1])
			m.normalizeSelection()
			m.adjustListOffset()
		}
		return m, nil
	case tea.KeyCtrlU:
		m.filterQuery = ""
		m.normalizeSelection()
		m.adjustListOffset()
		return m, nil
	}
	return m, nil
}

func (m model) handleHelpKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q":
		return m, tea.Quit
	case "esc", "?", ",":
		m.showHelp = false
		return m, nil
	}
	return m, nil
}

func (m model) handleBusyKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q":
		return m, tea.Quit
	}
	return m, nil
}

func (m model) handleConfirmKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "y", "enter":
		return m.confirmCmd()
	case "n", "esc":
		m.confirmKind = ""
		m.confirmText = ""
		m.statusText = "Cancelled"
		return m, nil
	case "ctrl+c", "q":
		return m, tea.Quit
	}
	return m, nil
}

func (m model) handleNormalKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	// View switching
	switch {
	case matchesPromptViewKey(msg):
		m.setDetailMode(detailPrompt)
		return m, nil
	case matchesHintViewKey(msg):
		if m.activeTab == labsTab {
			m.setDetailMode(detailHint)
		}
		return m, nil
	case matchesSolutionViewKey(msg):
		m.setDetailMode(detailSolution)
		return m, nil
	case matchesCheckViewKey(msg):
		if m.activeTab == labsTab {
			m.setDetailMode(detailCheck)
		} else {
			m.setDetailMode(detailPrompt)
		}
		return m, nil
	}

	switch msg.String() {
	case "ctrl+c", "q":
		return m, tea.Quit
	case "tab", "shift+tab":
		m.switchPaneFocus()
		return m, nil
	case "left":
		m.switchCatalogTab(-1)
		return m, nil
	case "right":
		m.switchCatalogTab(1)
		return m, nil
	case "esc":
		if m.focus == focusDetail {
			m.focus = focusList
			return m, nil
		}
		return m, nil
	case "up", "k":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(m.currentDetailOffset() - 1)
		} else {
			m.moveSelection(-1)
		}
		return m, nil
	case "down", "j":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(m.currentDetailOffset() + 1)
		} else {
			m.moveSelection(1)
		}
		return m, nil
	case "home", "g":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(0)
		} else {
			if m.activeTab == labsTab {
				m.selectedLab = 0
				m.touchViewed()
			} else {
				m.selectedExam = 0
			}
			m.adjustListOffset()
			m.resetDetailOffsets()
		}
		return m, nil
	case "end", "G":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(m.detailMaxOffset())
		} else {
			if m.activeTab == labsTab && len(m.filteredLabs()) > 0 {
				m.selectedLab = len(m.filteredLabs()) - 1
				m.touchViewed()
			} else if m.activeTab == examsTab && len(m.filteredExams()) > 0 {
				m.selectedExam = len(m.filteredExams()) - 1
			}
			m.adjustListOffset()
			m.resetDetailOffsets()
		}
		return m, nil
	case "pgup":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(m.currentDetailOffset() - m.detailPageStep())
		} else {
			m.moveSelection(-(m.listPageSize() - 1))
		}
		return m, nil
	case "ctrl+u":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(m.currentDetailOffset() - m.detailPageStep())
		} else {
			m.moveSelection(-(m.listPageSize() - 1))
		}
		return m, nil
	case "pgdown":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(m.currentDetailOffset() + m.detailPageStep())
		} else {
			m.moveSelection(m.listPageSize() - 1)
		}
		return m, nil
	case "ctrl+d":
		if m.focus == focusDetail {
			m.setCurrentDetailOffset(m.currentDetailOffset() + m.detailPageStep())
		} else {
			m.moveSelection(m.listPageSize() - 1)
		}
		return m, nil
	case "enter", "s":
		m.confirmKind = "start"
		m.confirmText = m.startConfirmText()
		m.statusText = m.confirmText
		return m, nil
	case "c":
		return m.handleCheckAction()
	case "r":
		return m.handleResetAction()
	case "z":
		return m.handleSSHAction("clientvm")
	case "x":
		return m.handleSSHAction("servervm")
	case "/", ":", "ctrl+f":
		m.filterMode = true
		if m.filterQuery == "" {
			m.statusText = "Search"
		} else {
			m.statusText = fmt.Sprintf("Search: %s", m.filterQuery)
		}
		return m, nil
	case "?", ",":
		m.showHelp = true
		return m, nil
	}

	return m, nil
}

func (m model) handleCheckAction() (tea.Model, tea.Cmd) {
	if !m.simulatorBuilt() {
		m.statusText = "Simulator not built\nRun 'RHCSA.ps1 up' or start a lab first"
		return m, nil
	}
	if m.activeTab != labsTab {
		m.statusText = "Checks are available for labs only"
		return m, nil
	}
	m.busy = true
	m.statusText = "Running checks"
	return m, m.checkSelectedLabCmd()
}

func (m model) handleResetAction() (tea.Model, tea.Cmd) {
	if !m.simulatorBuilt() {
		m.statusText = "Simulator not built\nRun 'RHCSA.ps1 up' or start a lab first"
		return m, nil
	}
	m.confirmKind = "reset"
	m.confirmText = "Reset the active run? Press y or Enter to confirm."
	m.statusText = m.confirmText
	return m, nil
}

func (m model) handleSSHAction(machine string) (tea.Model, tea.Cmd) {
	if !m.simulatorBuilt() {
		m.statusText = "Simulator not built\nRun 'RHCSA.ps1 up' or start a lab first"
		return m, nil
	}
	m.busy = true
	m.statusText = fmt.Sprintf("Opening SSH for %s", machine)
	return m, m.sshCmd(machine)
}

func (m model) startSelectedCmd() tea.Cmd {
	if m.activeTab == labsTab {
		lab := m.currentLab()
		return runActionCmd(m.runner, "start-lab", lab.ID, "start", "-Id", lab.ID, "-Mode", "Lab")
	}
	exam := m.currentExam()
	return runActionCmd(m.runner, "start-exam", exam.ID, "start", "-Id", exam.ID, "-Mode", "Exam")
}

func (m model) checkSelectedLabCmd() tea.Cmd {
	lab := m.currentLab()
	return runActionCmd(m.runner, "check-lab", lab.ID, "check", "-Id", lab.ID)
}

func (m model) resetCmd() tea.Cmd {
	return runActionCmd(m.runner, "reset", "", "reset")
}

func (m model) sshCmd(machine string) tea.Cmd {
	return runActionCmd(m.runner, "ssh-"+machine, "", "ssh", machine)
}

func (m model) confirmCmd() (tea.Model, tea.Cmd) {
	switch m.confirmKind {
	case "start":
		m.confirmKind = ""
		m.confirmText = ""
		m.busy = true
		m.statusText = m.startStatusText()
		return m, m.startSelectedCmd()
	case "reset":
		m.confirmKind = ""
		m.confirmText = ""
		m.busy = true
		m.statusText = "Resetting the active run..."
		return m, m.resetCmd()
	default:
		return m, nil
	}
}

func runActionCmd(runner *backend.Runner, kind, labID string, args ...string) tea.Cmd {
	return func() tea.Msg {
		output, err := runner.Run(args...)
		lowered := strings.ToLower(output)
		passed := err == nil && (strings.Contains(output, "All checks passed") || strings.Contains(lowered, "result: complete"))
		return actionResultMsg{
			kind:   kind,
			labID:  labID,
			output: output,
			err:    err,
			passed: passed,
		}
	}
}
