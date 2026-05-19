package main

import (
	"fmt"
	"os"
	"strings"
	"time"
	"unicode"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/firassBenNacib/rhcsa_exam_vms/internal/backend"
	"github.com/firassBenNacib/rhcsa_exam_vms/internal/progress"
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
	if m.timerEnabled {
		return scheduleUITick()
	}
	return nil
}

func scheduleUITick() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg {
		return uiTickMsg(t)
	})
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
	case uiTickMsg:
		m.now = time.Time(msg)
		if m.busy || m.timerEnabled {
			return m, scheduleUITick()
		}
		return m, nil
	case tea.KeyMsg:
		return m.handleKeyMsg(msg)
	}

	return m, nil
}

func isMousePress(msg tea.MouseMsg) bool {
	return msg.Button == tea.MouseButtonLeft && msg.Action == tea.MouseActionPress
}

func isRightClick(msg tea.MouseMsg) bool {
	return msg.Button == tea.MouseButtonRight && msg.Action == tea.MouseActionPress
}

func (m model) handleMouse(msg tea.MouseMsg) (tea.Model, tea.Cmd) {
	mouseX := msg.X
	mouseY := msg.Y

	if isRightClick(msg) {
		return m.handleRightClick(mouseX, mouseY)
	}

	if isMousePress(msg) && m.showHelp {
		if sx, ex, y, ok := m.helpCloseBtnBounds(); ok && mouseY == y && mouseX >= sx && mouseX <= ex {
			m.showHelp = false
			return m, nil
		}
		return m, nil
	}

	if isMousePress(msg) && !m.showHelp {
		if sx, ex, y, ok := m.timerButtonBounds(); ok && mouseY == y && mouseX >= sx && mouseX <= ex {
			return m.toggleTimer()
		}
	}

	if isMousePress(msg) && !m.showHelp && !m.busy {
		if m.confirmKind != "" {
			if m.confirmKind == "start" && m.mouseInListPane(mouseX, mouseY) {
				index, ok := m.selectListRowAt(mouseY)
				if ok && m.isListDoubleClick(index) {
					return m.confirmCmd()
				}
				if ok {
					m.recordListClick(index)
				}
				return m, nil
			}
			if next, cmd, ok := m.handleConfirmFooterClick(mouseX, mouseY); ok {
				return next, cmd
			}
			return m, nil
		}
		if next, cmd, ok := m.handleFooterClick(mouseX, mouseY); ok {
			return next, cmd
		}
	}

	if m.showHelp || m.busy || m.confirmKind != "" {
		return m, nil
	}

	switch {
	case msg.Action == tea.MouseActionMotion:
		return m, nil
	case msg.Action == tea.MouseActionRelease:
		return m, nil
	case msg.Button == tea.MouseButtonWheelUp:
		if m.mouseInDetailPane(mouseX, mouseY) {
			m.focus = focusDetail
			m.setCurrentDetailOffset(m.currentDetailOffset() - 3)
			return m, nil
		}
		if m.mouseInListPane(mouseX, mouseY) {
			m.focus = focusList
			m.moveSelection(-1)
			return m, nil
		}
	case msg.Button == tea.MouseButtonWheelDown:
		if m.mouseInDetailPane(mouseX, mouseY) {
			m.focus = focusDetail
			m.setCurrentDetailOffset(m.currentDetailOffset() + 3)
			return m, nil
		}
		if m.mouseInListPane(mouseX, mouseY) {
			m.focus = focusList
			m.moveSelection(1)
			return m, nil
		}
	case msg.Button == tea.MouseButtonLeft && msg.Action == tea.MouseActionPress:
		if labsStart, labsEnd, examsStart, examsEnd, y := m.catalogTabBounds(); mouseY == y {
			switch {
			case mouseX >= labsStart && mouseX <= labsEnd:
				m.activeTab = labsTab
				m.ensureValidDetailMode()
				m.normalizeSelection()
				m.adjustListOffset()
				m.resetDetailOffsets()
				m.focus = focusList
				m.touchViewed()
				return m, nil
			case mouseX >= examsStart && mouseX <= examsEnd:
				m.activeTab = examsTab
				m.ensureValidDetailMode()
				m.normalizeSelection()
				m.adjustListOffset()
				m.resetDetailOffsets()
				m.focus = focusList
				return m, nil
			}
		}
		if _, originY := m.detailPaneOrigin(); mouseY == originY {
			for mode, bounds := range m.detailTabBounds() {
				if mouseX >= bounds[0] && mouseX <= bounds[1] {
					m.focus = focusDetail
					m.setDetailMode(mode)
					return m, nil
				}
			}
		}
		for _, bound := range m.detailSectionCopyBounds() {
			if mouseY == bound.y && bound.contains(mouseX) {
				m.focus = focusDetail
				return m.copyDetailSection(bound.section), nil
			}
		}
		if m.mouseInListPane(mouseX, mouseY) {
			m.focus = focusList
			index, ok := m.selectListRowAt(mouseY)
			if ok && m.isListDoubleClick(index) {
				m.filterMode = false
				m.confirmKind = "start"
				m.confirmText = m.startConfirmText()
				m.statusText = m.confirmText
				m.recordListClick(index)
				return m, nil
			}
			if ok {
				m.recordListClick(index)
			}
			return m, nil
		}
		if m.mouseInDetailPane(mouseX, mouseY) {
			m.focus = focusDetail
			return m, nil
		}
	}
	return m, nil
}

func (m model) handleRightClick(mouseX, mouseY int) (tea.Model, tea.Cmd) {
	if m.showHelp {
		m.showHelp = false
		return m, nil
	}
	if m.confirmKind != "" {
		m.confirmKind = ""
		m.confirmText = ""
		m.statusText = "Cancelled"
		return m, nil
	}
	if m.filterMode {
		if m.filterQuery != "" {
			m.filterQuery = ""
			m.normalizeSelection()
			m.adjustListOffset()
			return m, nil
		}
		m.filterMode = false
		m.statusText = ""
		return m, nil
	}
	if strings.TrimSpace(m.statusText) != "" {
		m.statusText = ""
		return m, nil
	}
	if !m.busy && m.mouseInListPane(mouseX, mouseY) {
		index, ok := m.selectListRowAt(mouseY)
		if ok {
			m.refreshActiveScenarioID()
			if m.isListDoubleClick(index) {
				m.recordListClick(index)
				if m.cachedActiveID != "" && m.currentScenarioID() == m.cachedActiveID {
					return m.confirmExitRunAction()
				}
				m.statusText = "Select the active lab or exam to exit it"
				return m, nil
			}
			m.recordListClick(index)
			return m, nil
		}
	}
	if m.focus == focusDetail {
		m.focus = focusList
		return m, nil
	}
	return m, nil
}

func (m model) handleFooterClick(mouseX, mouseY int) (tea.Model, tea.Cmd, bool) {
	for _, bound := range m.footerActionBounds(m.width) {
		if mouseY == bound.y && hitHorizontalBound(mouseX, bound.startX, bound.endX) {
			next, cmd := m.handleFooterAction(bound.id)
			return next, cmd, true
		}
	}
	return m, nil, false
}

func hitHorizontalBound(x, startX, endX int) bool {
	return (x >= startX && x <= endX) || (x-1 >= startX && x-1 <= endX)
}

func (m model) handleConfirmFooterClick(mouseX, mouseY int) (tea.Model, tea.Cmd, bool) {
	for _, bound := range m.footerActionBounds(m.width) {
		if mouseY == bound.y && hitHorizontalBound(mouseX, bound.startX, bound.endX) {
			var confirmAction footerActionID
			switch m.confirmKind {
			case "start":
				confirmAction = footerActionStart
			case "reset":
				confirmAction = footerActionReset
			case "exit-run":
				confirmAction = footerActionExitRun
			}
			if bound.id == confirmAction {
				next, cmd := m.confirmCmd()
				return next, cmd, true
			}
			m.confirmKind = ""
			m.confirmText = ""
			m.statusText = "Cancelled"
			return m, nil, true
		}
	}
	return m, nil, false
}

func (m model) handleFooterAction(action footerActionID) (tea.Model, tea.Cmd) {
	switch action {
	case footerActionStart:
		m.confirmKind = "start"
		m.confirmText = m.startConfirmText()
		m.statusText = m.confirmText
		return m, nil
	case footerActionReset:
		return m.handleResetAction()
	case footerActionExitRun:
		return m.confirmExitRunAction()
	case footerActionPane:
		m.switchPaneFocus()
		return m, nil
	case footerActionSwitch:
		if m.focus == focusDetail {
			m.cycleDetailMode(1)
		} else {
			if m.activeTab == labsTab {
				m.switchCatalogTab(1)
			} else {
				m.switchCatalogTab(-1)
			}
		}
		return m, nil
	case footerActionCheck:
		return m.handleCheckAction()
	case footerActionTasks:
		m.setDetailMode(detailPrompt)
		return m, nil
	case footerActionHints:
		if m.activeTab == labsTab {
			m.setDetailMode(detailHint)
		}
		return m, nil
	case footerActionChecks:
		m.setDetailMode(detailCheck)
		return m, nil
	case footerActionSolutions:
		m.setDetailMode(detailSolution)
		return m, nil
	case footerActionFind:
		m.filterMode = true
		m.statusText = ""
		return m, nil
	case footerActionHelp:
		m.showHelp = true
		return m, nil
	case footerActionQuit:
		return m, tea.Quit
	case footerActionFilterKeep:
		m.filterMode = false
		m.statusText = ""
		return m, nil
	case footerActionFilterClear:
		m.filterQuery = ""
		m.normalizeSelection()
		m.adjustListOffset()
		m.filterMode = false
		m.statusText = ""
		return m, nil
	case footerActionSSHClient:
		return m.handleSSHAction("client")
	case footerActionSSHServer:
		return m.handleSSHAction("server")
	case footerActionTimer:
		return m.toggleTimer()
	default:
		return m, nil
	}
}

func (m model) mouseInListPane(x, y int) bool {
	contentY := 2
	if y < contentY {
		return false
	}
	if m.useStackedLayout() {
		return y < contentY+m.listPaneHeight()
	}
	return x >= 0 && x < m.listPaneWidth() && y < contentY+m.contentHeight()
}

func (m model) mouseInDetailPane(x, y int) bool {
	originX, originY := m.detailPaneOrigin()
	return x >= originX && x < originX+m.detailPaneWidth() && y >= originY && y < originY+m.detailPaneHeight()
}

func (m *model) selectListRowAt(y int) (int, bool) {
	contentY := 2
	listY := y - contentY
	if m.useStackedLayout() {
		if listY < 0 || listY >= m.listPaneHeight() {
			return -1, false
		}
	} else if listY < 0 || listY >= m.contentHeight() {
		return -1, false
	}

	row := listY - 2
	if row < 0 {
		return -1, false
	}

	index := m.listOffset + row
	if m.activeTab == labsTab {
		labs := m.filteredLabs()
		if index < 0 || index >= len(labs) {
			return -1, false
		}
		m.selectedLab = index
		m.touchViewed()
	} else {
		exams := m.filteredExams()
		if index < 0 || index >= len(exams) {
			return -1, false
		}
		m.selectedExam = index
	}
	m.adjustListOffset()
	m.resetDetailOffsets()
	return index, true
}

func (m model) isListDoubleClick(index int) bool {
	if index < 0 || m.lastListClickIndex != index || m.lastListClickTab != m.activeTab {
		return false
	}
	return time.Since(m.lastListClickAt) <= 550*time.Millisecond
}

func (m *model) recordListClick(index int) {
	m.lastListClickTab = m.activeTab
	m.lastListClickIndex = index
	m.lastListClickAt = time.Now()
}

func (m model) copyDetailSection(index int) model {
	sections := m.copyableSections()
	if index < 0 || index >= len(sections) {
		m.statusText = "Copy target is unavailable"
		return m
	}
	if err := clipboardCopy(sections[index].content); err != nil {
		m.statusText = "Clipboard copy failed\n" + err.Error()
		return m
	}
	m.statusText = fmt.Sprintf("Copied %s", sections[index].title)
	return m
}

func (m model) handleActionResult(msg actionResultMsg) (tea.Model, tea.Cmd) {
	m.busy = false
	m.actionStarted = time.Time{}
	if msg.err != nil {
		m.statusText = summarizeActionOutput(msg.output)
		if m.statusText == "" {
			m.statusText = msg.err.Error()
		}
	} else {
		m.statusText = summarizeActionOutput(msg.output)
		track := preferredTrack(msg.track, nil)
		if msg.kind == "start-lab" {
			m.refreshActiveScenarioID()
			if m.timerEnabled || m.timerDefaultEnabled {
				m.now = time.Now()
				m.timerEnabled = true
				m.timerEndsAt = m.timerStartDeadline()
			}
			m.progress.TouchStarted(progress.CompositeKey(track, msg.labID))
			if err := m.progress.Save(m.progressPath); err != nil {
				m.statusText += "\nWarning: Failed to save progress: " + err.Error()
			}
		}
		if msg.kind == "start-exam" {
			m.refreshActiveScenarioID()
			if m.timerEnabled || m.timerDefaultEnabled {
				m.now = time.Now()
				m.timerEnabled = true
				m.timerEndsAt = m.timerStartDeadline()
			}
			m.progress.TouchExamStarted(progress.CompositeKey(track, msg.labID))
			if err := m.progress.Save(m.progressPath); err != nil {
				m.statusText += "\nWarning: Failed to save progress: " + err.Error()
			}
		}
		if msg.kind == "check-lab" {
			m.progress.TouchChecked(progress.CompositeKey(track, msg.labID), msg.passed)
			if err := m.progress.Save(m.progressPath); err != nil {
				m.statusText += "\nWarning: Failed to save progress: " + err.Error()
			}
		}
		if msg.kind == "check-exam" {
			m.progress.TouchExamChecked(progress.CompositeKey(track, msg.labID), msg.passed)
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
	case tea.KeyUp:
		m.moveSelection(-1)
		return m, nil
	case tea.KeyDown:
		m.moveSelection(1)
		return m, nil
	case tea.KeyPgUp:
		m.moveSelection(-(m.listPageSize() - 1))
		return m, nil
	case tea.KeyPgDown:
		m.moveSelection(m.listPageSize() - 1)
		return m, nil
	case tea.KeyHome:
		if m.activeTab == labsTab {
			m.selectedLab = 0
			m.touchViewed()
		} else {
			m.selectedExam = 0
		}
		m.adjustListOffset()
		m.resetDetailOffsets()
		return m, nil
	case tea.KeyEnd:
		if m.activeTab == labsTab && len(m.filteredLabs()) > 0 {
			m.selectedLab = len(m.filteredLabs()) - 1
			m.touchViewed()
		} else if m.activeTab == examsTab && len(m.filteredExams()) > 0 {
			m.selectedExam = len(m.filteredExams()) - 1
		}
		m.adjustListOffset()
		m.resetDetailOffsets()
		return m, nil
	case tea.KeyTab, tea.KeyShiftTab, tea.KeyLeft, tea.KeyRight:
		if m.activeTab == labsTab {
			m.switchCatalogTab(1)
		} else {
			m.switchCatalogTab(-1)
		}
		m.normalizeSelection()
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
	switch msg.String() {
	case "k":
		m.moveSelection(-1)
		return m, nil
	case "j":
		m.moveSelection(1)
		return m, nil
	case "g":
		if m.activeTab == labsTab {
			m.selectedLab = 0
			m.touchViewed()
		} else {
			m.selectedExam = 0
		}
		m.adjustListOffset()
		m.resetDetailOffsets()
		return m, nil
	case "G":
		if m.activeTab == labsTab && len(m.filteredLabs()) > 0 {
			m.selectedLab = len(m.filteredLabs()) - 1
			m.touchViewed()
		} else if m.activeTab == examsTab && len(m.filteredExams()) > 0 {
			m.selectedExam = len(m.filteredExams()) - 1
		}
		m.adjustListOffset()
		m.resetDetailOffsets()
		return m, nil
	}
	if text, ok := filterTextForKey(msg); ok {
		m.filterQuery += text
		m.normalizeSelection()
		m.adjustListOffset()
		return m, nil
	}
	return m, nil
}

func (m model) handleHelpKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q", "Q":
		return m, tea.Quit
	case "esc", "?", ",":
		m.showHelp = false
		return m, nil
	}
	return m, nil
}

func (m model) handleBusyKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q", "Q":
		return m, tea.Quit
	case "t", "T":
		return m.toggleTimer()
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
	case "ctrl+c", "q", "Q":
		return m, tea.Quit
	}
	return m, nil
}

func (m model) handleNormalKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
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
		m.setDetailMode(detailCheck)
		return m, nil
	}

	switch msg.String() {
	case "ctrl+c", "q", "Q":
		return m, tea.Quit
	case "t", "T":
		return m.toggleTimer()
	case "tab", "shift+tab":
		m.switchPaneFocus()
		return m, nil
	case "left":
		if m.focus == focusDetail {
			m.cycleDetailMode(-1)
		} else {
			m.switchCatalogTab(-1)
		}
		return m, nil
	case "right":
		if m.focus == focusDetail {
			m.cycleDetailMode(1)
		} else {
			m.switchCatalogTab(1)
		}
		return m, nil
	case "esc":
		if strings.TrimSpace(m.statusText) != "" {
			m.statusText = ""
			return m, nil
		}
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
			m.setCurrentDetailOffset(m.previousDetailSectionOffset())
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
			m.setCurrentDetailOffset(m.nextDetailSectionOffset())
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
	case "enter", "s", "S":
		m.confirmKind = "start"
		m.confirmText = m.startConfirmText()
		m.statusText = m.confirmText
		return m, nil
	case "c", "C":
		return m.handleCheckAction()
	case "r", "R":
		return m.handleResetAction()
	case "e", "E":
		return m.confirmExitRunAction()
	case "z", "Z":
		return m.handleSSHAction("client")
	case "x", "X":
		return m.handleSSHAction("server")
	case "/", ":", "ctrl+f":
		m.filterMode = true
		m.statusText = ""
		return m, nil
	case "?", ",", "H":
		m.showHelp = true
		return m, nil
	}

	return m, nil
}

func (m model) handleCheckAction() (tea.Model, tea.Cmd) {
	if !m.simulatorBuilt() {
		m.statusText = "Simulator not built\nRun 'RHCSA.ps1 up' or start a lab or exam first"
		return m, nil
	}
	m.refreshActiveScenarioID()
	activeID := m.activeScenarioID()
	if activeID == "" {
		m.statusText = "No active lab or exam\nStart a lab or exam before running checks"
		return m, nil
	}
	m.busy = true
	m.actionStarted = time.Now()
	mode := m.activeScenarioMode()
	if mode == "" {
		mode = m.scenarioModeByID(activeID)
	}
	if activeID != m.currentScenarioID() {
		m.statusText = fmt.Sprintf("Checking %s (active run)", activeID)
	} else {
		m.statusText = "Running checks"
	}
	return m, tea.Batch(m.checkActiveRunCmd(activeID, mode), scheduleUITick())
}

func (m model) handleResetAction() (tea.Model, tea.Cmd) {
	if !m.simulatorBuilt() {
		m.statusText = "Simulator not built\nRun 'RHCSA.ps1 up' or start a lab first"
		return m, nil
	}
	m.confirmKind = "reset"
	m.confirmText = "Reset the active run? Click Reset or press y/Enter to confirm."
	m.statusText = m.confirmText
	return m, nil
}

func (m model) confirmExitRunAction() (tea.Model, tea.Cmd) {
	m.refreshActiveScenarioID()
	activeID := m.activeScenarioID()
	if activeID == "" {
		m.timerEnabled = false
		m.timerEndsAt = time.Time{}
		m.statusText = "No active lab or exam"
		return m, nil
	}

	m.confirmKind = "exit-run"
	m.confirmText = fmt.Sprintf("Exit %s? Press y/Enter or click Exit.", activeID)
	m.statusText = m.confirmText
	return m, nil
}

func (m model) handleExitRunAction() (tea.Model, tea.Cmd) {
	m.refreshActiveScenarioID()
	activeID := m.activeScenarioID()
	if activeID == "" {
		m.timerEnabled = false
		m.timerEndsAt = time.Time{}
		m.statusText = "No active lab or exam"
		return m, nil
	}

	if err := os.Remove(m.activeRunPath()); err != nil && !os.IsNotExist(err) {
		m.statusText = "Exit run failed\n" + err.Error()
		return m, nil
	}

	m.cachedActiveID = ""
	m.cachedActiveMode = ""
	m.cachedStartedAt = time.Time{}
	m.cachedEndsAt = time.Time{}
	m.cachedTimeLimitMinutes = 0
	m.timerEnabled = false
	m.timerEndsAt = time.Time{}
	m.statusText = fmt.Sprintf("Exited %s", activeID)
	return m, nil
}

func (m model) handleSSHAction(machine string) (tea.Model, tea.Cmd) {
	if !m.simulatorBuilt() {
		m.statusText = "Simulator not built\nRun 'RHCSA.ps1 up' or start a lab first"
		return m, nil
	}
	m.refreshActiveScenarioID()
	if m.activeScenarioID() == "" {
		m.statusText = "No active lab or exam\nStart a lab or exam before opening SSH"
		return m, nil
	}
	m.busy = true
	m.actionStarted = time.Now()
	m.statusText = fmt.Sprintf("Opening SSH for %s", machine)
	return m, tea.Batch(m.sshCmd(machine), scheduleUITick())
}

func (m model) startSelectedCmd() tea.Cmd {
	if m.activeTab == labsTab {
		lab := m.currentLab()
		track := preferredTrack(m.track, lab.Tracks)
		return runActionCmd(m.runner, "start-lab", lab.ID, track, "start", "-Id", lab.ID, "-Mode", "Lab", "-Track", track)
	}
	exam := m.currentExam()
	track := preferredTrack(m.track, exam.Tracks)
	return runActionCmd(m.runner, "start-exam", exam.ID, track, "start", "-Id", exam.ID, "-Mode", "Exam", "-Track", track)
}

func (m model) startSelectedNow() (tea.Model, tea.Cmd) {
	m.confirmKind = ""
	m.confirmText = ""
	m.busy = true
	m.actionStarted = time.Now()
	m.statusText = m.startStatusText()
	if m.timerEnabled {
		m.now = m.actionStarted
		m.timerEndsAt = m.timerStartDeadline()
	}
	return m, tea.Batch(m.startSelectedCmd(), scheduleUITick())
}

func (m model) checkActiveRunCmd(activeID, mode string) tea.Cmd {
	track := preferredTrack(m.track, m.scenarioTracksByID(activeID))
	kind := "check-lab"
	if mode == "exam" {
		kind = "check-exam"
	}
	return runActionCmd(m.runner, kind, activeID, track, "check")
}

func (m model) resetCmd() tea.Cmd {
	return runActionCmd(m.runner, "reset", "", "", "reset")
}

func (m model) sshCmd(machine string) tea.Cmd {
	return runActionCmd(m.runner, "ssh-"+machine, "", "", "ssh", machine)
}

func (m model) confirmCmd() (tea.Model, tea.Cmd) {
	switch m.confirmKind {
	case "start":
		return m.startSelectedNow()
	case "reset":
		m.confirmKind = ""
		m.confirmText = ""
		m.busy = true
		m.actionStarted = time.Now()
		m.statusText = "Resetting the active run..."
		return m, tea.Batch(m.resetCmd(), scheduleUITick())
	case "exit-run":
		m.confirmKind = ""
		m.confirmText = ""
		return m.handleExitRunAction()
	default:
		return m, nil
	}
}

func (m model) toggleTimer() (tea.Model, tea.Cmd) {
	m.now = time.Now()
	m.refreshActiveScenarioID()
	if m.timerEnabled {
		m.timerEnabled = false
		m.timerEndsAt = time.Time{}
		m.statusText = ""
		return m, nil
	}

	if m.cachedActiveID == "" {
		m.timerEnabled = false
		m.timerEndsAt = time.Time{}
		m.statusText = ""
		return m, nil
	}

	deadline, err := m.restartActiveRunTimer(m.now)
	if err != nil {
		m.timerEnabled = false
		m.timerEndsAt = time.Time{}
		m.statusText = "Timer restart failed\n" + err.Error()
		return m, nil
	}

	m.timerEnabled = true
	m.timerEndsAt = deadline
	m.statusText = ""
	return m, scheduleUITick()
}

func (m model) timerStartDeadline() time.Time {
	if !m.cachedEndsAt.IsZero() {
		return m.cachedEndsAt
	}
	if m.cachedStartedAt.IsZero() {
		return time.Time{}
	}
	minutes := m.cachedTimeLimitMinutes
	if minutes <= 0 {
		return time.Time{}
	}
	return m.cachedStartedAt.Add(time.Duration(minutes) * time.Minute)
}

func runActionCmd(runner *backend.Runner, kind, labID, track string, args ...string) tea.Cmd {
	return func() tea.Msg {
		output, err := runner.Run(args...)
		return actionResultMsg{
			kind:   kind,
			labID:  labID,
			track:  track,
			output: output,
			err:    err,
			passed: actionOutputPassed(output, err),
		}
	}
}

func actionOutputPassed(output string, err error) bool {
	if err != nil {
		return false
	}
	plainOutput := StripAnsi(output)
	lowered := strings.ToLower(plainOutput)
	return strings.Contains(plainOutput, "All checks passed") ||
		strings.Contains(lowered, "result: complete") ||
		strings.Contains(plainOutput, "Score: 100/100")
}
