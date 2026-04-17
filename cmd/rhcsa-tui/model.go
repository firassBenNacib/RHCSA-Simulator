package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/lipgloss"

	"rhcsa_exam_vms/internal/backend"
	"rhcsa_exam_vms/internal/catalog"
	"rhcsa_exam_vms/internal/progress"
	"rhcsa_exam_vms/internal/utils"
)

// StripAnsi is a convenience wrapper around utils.StripAnsi.
func StripAnsi(s string) string {
	return utils.StripAnsi(s)
}

type tabName int

const (
	labsTab tabName = iota
	examsTab
)

type detailMode int

const (
	detailPrompt detailMode = iota
	detailHint
	detailSolution
	detailCheck
)

type paneFocus int

const (
	focusList paneFocus = iota
	focusDetail
)

type actionResultMsg struct {
	kind   string
	labID  string
	output string
	err    error
	passed bool
}

type model struct {
	root         string
	labs         []catalog.Lab
	exams        []catalog.Exam
	runner       *backend.Runner
	progress     *progress.State
	progressPath string
	theme        Theme

	activeTab      tabName
	detail         detailMode
	focus          paneFocus
	selectedLab    int
	selectedExam   int
	listOffset     int
	detailOffsets  [4]int
	width          int
	height         int
	statusText     string
	showHelp       bool
	busy           bool
	confirmKind    string
	confirmText    string
	filterMode     bool
	filterQuery    string
	cachedActiveID string
}

func newModel(root string, labs []catalog.Lab, exams []catalog.Exam, runner *backend.Runner, progressState *progress.State, progressPath string) model {
	m := model{
		root:         root,
		labs:         labs,
		exams:        exams,
		runner:       runner,
		progress:     progressState,
		progressPath: progressPath,
		theme:        NewTheme(),
		activeTab:    labsTab,
		detail:       detailPrompt,
		focus:        focusList,
	}
	m.refreshActiveScenarioID()
	m.touchViewed()
	return m
}

// ── Active scenario tracking ───────────────────────────────

func (m *model) refreshActiveScenarioID() {
	type activeScenario struct {
		Scenario struct {
			ID string `json:"id"`
		} `json:"scenario"`
	}

	raw, err := os.ReadFile(filepath.Join(m.root, ".lab-state", "active-run.json"))
	if err != nil {
		m.cachedActiveID = ""
		return
	}

	var state activeScenario
	if err := json.Unmarshal(raw, &state); err != nil {
		m.cachedActiveID = ""
		return
	}
	m.cachedActiveID = state.Scenario.ID
}

func (m model) activeScenarioID() string {
	return m.cachedActiveID
}

// ── Progress helpers ───────────────────────────────────────

func (m model) progressMarker(id string) string {
	if m.progress == nil {
		return " "
	}
	return m.progress.Marker(id)
}

func (m model) examProgressMarker(id string) string {
	if m.progress == nil {
		return " "
	}
	return m.progress.ExamMarker(id)
}

func (m model) simulatorBuilt() bool {
	_, err := os.Stat(filepath.Join(m.root, ".vagrant", "machines"))
	return err == nil
}

func (m *model) touchViewed() {
	if len(m.labs) == 0 && len(m.exams) == 0 {
		return
	}
	if m.activeTab == labsTab {
		if lab := m.currentLab(); lab.ID != "" {
			m.progress.TouchViewed(lab.ID)
		}
	} else {
		if exam := m.currentExam(); exam.ID != "" {
			m.progress.TouchExamViewed(exam.ID)
		}
	}
}

// ── Selection & filtering ──────────────────────────────────

func (m model) currentLab() catalog.Lab {
	labs := m.filteredLabs()
	if len(labs) == 0 {
		return catalog.Lab{}
	}
	return labs[utils.Clamp(m.selectedLab, 0, len(labs)-1)]
}

func (m model) currentExam() catalog.Exam {
	exams := m.filteredExams()
	if len(exams) == 0 {
		return catalog.Exam{}
	}
	return exams[utils.Clamp(m.selectedExam, 0, len(exams)-1)]
}

func (m model) filteredLabs() []catalog.Lab {
	return filterItems(m.labs, m.filterQuery, func(lab catalog.Lab) string {
		return strings.ToLower(strings.Join([]string{
			lab.ID, lab.Title, lab.Description, strings.Join(lab.ObjectiveTags, " "),
		}, " "))
	})
}

func (m model) filteredExams() []catalog.Exam {
	return filterItems(m.exams, m.filterQuery, func(exam catalog.Exam) string {
		return strings.ToLower(strings.Join([]string{
			exam.ID, exam.Title, exam.Description, strings.Join(exam.ObjectiveTags, " "),
		}, " "))
	})
}

func filterItems[T any](items []T, query string, keyFunc func(T) string) []T {
	if strings.TrimSpace(query) == "" {
		return items
	}
	q := strings.ToLower(strings.TrimSpace(query))
	filtered := make([]T, 0, len(items))
	for _, item := range items {
		if strings.Contains(keyFunc(item), q) {
			filtered = append(filtered, item)
		}
	}
	return filtered
}

// ── Navigation ─────────────────────────────────────────────

func (m *model) moveSelection(delta int) {
	if m.activeTab == labsTab {
		labs := m.filteredLabs()
		if len(labs) == 0 {
			return
		}
		m.selectedLab = utils.Clamp(m.selectedLab+delta, 0, len(labs)-1)
	} else {
		exams := m.filteredExams()
		if len(exams) == 0 {
			return
		}
		m.selectedExam = utils.Clamp(m.selectedExam+delta, 0, len(exams)-1)
	}
	m.adjustListOffset()
	m.resetDetailOffsets()
	m.touchViewed()
}

func (m *model) normalizeSelection() {
	if m.activeTab == labsTab {
		total := len(m.filteredLabs())
		if total == 0 {
			m.selectedLab = 0
			m.listOffset = 0
			return
		}
		m.selectedLab = utils.Clamp(m.selectedLab, 0, total-1)
	} else {
		total := len(m.filteredExams())
		if total == 0 {
			m.selectedExam = 0
			m.listOffset = 0
			return
		}
		m.selectedExam = utils.Clamp(m.selectedExam, 0, total-1)
	}
}

func (m *model) adjustListOffset() {
	pageSize := m.listPageSize()
	if pageSize < 1 {
		return
	}

	selected := m.selectedExam
	total := len(m.filteredExams())
	if m.activeTab == labsTab {
		selected = m.selectedLab
		total = len(m.filteredLabs())
	}

	if selected < m.listOffset {
		m.listOffset = selected
	}
	if selected >= m.listOffset+pageSize {
		m.listOffset = selected - pageSize + 1
	}
	m.listOffset = utils.Clamp(m.listOffset, 0, utils.MaxInt(total-pageSize, 0))
}

// ── Layout constants ───────────────────────────────────────

const (
	minWideLayoutWidth  = 100
	minWideLayoutHeight = 24
	maxStatusHeight     = 12
	minStatusHeight     = 4
	// header(1) + tabBar(2) + footer(1) = 4 lines of chrome
	chromeHeight          = 4
	minContentHeight      = 4
	minDetailTextWidth    = 20
	listPaneBorder        = 3
	detailPaneBorder      = 5
	defaultMaxStatusLines = 10
)

// ── Layout helpers ─────────────────────────────────────────

func (m model) useStackedLayout() bool {
	return m.width < minWideLayoutWidth || m.height < minWideLayoutHeight
}

func (m model) listPaneWidth() int {
	if m.useStackedLayout() {
		return m.width
	}
	return utils.MaxInt((m.width*2)/5, 30)
}

func (m model) detailTextWidth() int {
	if m.useStackedLayout() {
		return utils.MaxInt(m.width-detailPaneBorder, minDetailTextWidth)
	}
	rightWidth := m.width - m.listPaneWidth() - 1
	return utils.MaxInt(rightWidth-detailPaneBorder, minDetailTextWidth)
}

func (m model) statusPaneHeight() int {
	if strings.TrimSpace(m.statusText) == "" && !m.busy && !m.filterMode && m.confirmKind == "" {
		return 0
	}

	lineCount := len(strings.Split(strings.TrimSpace(m.statusBody()), "\n"))
	if lineCount < 1 {
		lineCount = 1
	}

	desired := lineCount + 4
	maxAllowed := utils.MaxInt(m.height/3, minStatusHeight)
	if maxAllowed > maxStatusHeight {
		maxAllowed = maxStatusHeight
	}
	desired = utils.Clamp(desired, minStatusHeight, maxAllowed)
	return desired
}

func (m model) contentHeight() int {
	h := m.height - chromeHeight - m.statusPaneHeight()
	return utils.MaxInt(h, minContentHeight)
}

func (m model) listPaneHeight() int {
	ch := m.contentHeight()
	if m.useStackedLayout() {
		return utils.MaxInt(ch/3, 6)
	}
	return ch
}

func (m model) detailPaneHeight() int {
	ch := m.contentHeight()
	if m.useStackedLayout() {
		return utils.MaxInt(ch-m.listPaneHeight(), 6)
	}
	return ch
}

func (m model) listPageSize() int {
	return utils.MaxInt(m.listPaneHeight()-2, 1)
}

func (m model) visibleRange(total int) (int, int) {
	pageSize := m.listPageSize()
	start := utils.Clamp(m.listOffset, 0, utils.MaxInt(total-pageSize, 0))
	end := start + pageSize
	if end > total {
		end = total
	}
	return start, end
}

func (m model) detailVisibleLines() int {
	return utils.MaxInt(m.detailPaneHeight()-detailPaneBorder, 1)
}

func (m model) detailPageStep() int {
	return utils.MaxInt(m.detailVisibleLines()-3, 1)
}

func (m model) detailMaxOffset() int {
	lines := strings.Split(m.renderDetailBody(), "\n")
	return utils.MaxInt(len(lines)-m.detailVisibleLines(), 0)
}

func (m model) currentDetailOffset() int {
	return m.detailOffsets[m.detail]
}

func (m *model) setCurrentDetailOffset(offset int) {
	m.detailOffsets[m.detail] = utils.Clamp(offset, 0, m.detailMaxOffset())
}

func (m *model) resetDetailOffsets() {
	for i := range m.detailOffsets {
		m.detailOffsets[i] = 0
	}
}

func (m *model) ensureValidDetailMode() {
	if m.activeTab == examsTab && (m.detail == detailHint || m.detail == detailCheck) {
		m.detail = detailPrompt
	}
}

func (m *model) setDetailMode(mode detailMode) {
	if m.activeTab == examsTab && (mode == detailHint || mode == detailCheck) {
		mode = detailPrompt
	}
	m.detail = mode
	if m.activeTab == labsTab {
		m.touchViewed()
	}
	m.setCurrentDetailOffset(m.currentDetailOffset())
}

func (m *model) switchPaneFocus() {
	if m.focus == focusList {
		m.focus = focusDetail
		return
	}
	m.focus = focusList
}

func (m *model) switchCatalogTab(delta int) {
	if delta == 0 {
		return
	}
	if delta < 0 {
		m.activeTab = labsTab
	} else {
		m.activeTab = examsTab
	}
	m.ensureValidDetailMode()
	m.adjustListOffset()
	m.resetDetailOffsets()
	if m.activeTab == labsTab {
		m.touchViewed()
	}
}

func (m model) availableDetailModes() []detailMode {
	if m.activeTab == examsTab {
		return []detailMode{detailPrompt, detailSolution}
	}
	return []detailMode{detailPrompt, detailHint, detailCheck, detailSolution}
}

func (m *model) cycleDetailMode(delta int) {
	modes := m.availableDetailModes()
	if len(modes) == 0 || delta == 0 {
		return
	}

	index := 0
	for i, mode := range modes {
		if mode == m.detail {
			index = i
			break
		}
	}

	index = (index + delta + len(modes)) % len(modes)
	m.setDetailMode(modes[index])
}

func (m model) selectionProgressLabel() string {
	total := len(m.filteredExams())
	selected := m.selectedExam + 1
	if m.activeTab == labsTab {
		total = len(m.filteredLabs())
		selected = m.selectedLab + 1
	}
	if total == 0 {
		return "0 / 0"
	}
	if selected < 1 {
		selected = 1
	}
	if selected > total {
		selected = total
	}
	return fmt.Sprintf("%d / %d", selected, total)
}

// ── Confirm / status text helpers ──────────────────────────

func (m model) startConfirmText() string {
	if m.activeTab == labsTab {
		return fmt.Sprintf("Start %s? Press y or Enter to confirm.", m.currentLab().ID)
	}
	return fmt.Sprintf("Start %s? Press y or Enter to confirm.", m.currentExam().ID)
}

func (m model) startStatusText() string {
	if m.activeTab == labsTab {
		return fmt.Sprintf("Starting %s…", m.currentLab().ID)
	}
	return fmt.Sprintf("Starting %s…", m.currentExam().ID)
}

// ── Status body rendering ──────────────────────────────────

func (m model) statusBody() string {
	if strings.TrimSpace(m.statusText) == "" {
		return ""
	}

	width := utils.MaxInt(m.width-detailPaneBorder, minDetailTextWidth)
	lines := strings.Split(m.statusText, "\n")
	rendered := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			rendered = append(rendered, "")
			continue
		}
		rendered = appendWrappedLines(rendered, line, width, m.statusLineStyle(line))
	}
	return strings.Join(rendered, "\n")
}

func (m model) statusLineStyle(line string) lipgloss.Style {
	switch m.statusLineTone(line) {
	case "error":
		return m.theme.OutputError
	case "success":
		return m.theme.OutputSuccess
	case "warning":
		return m.theme.OutputWarning
	case "muted":
		return m.theme.OutputMuted
	case "info":
		return m.theme.OutputInfo
	default:
		return lipgloss.NewStyle()
	}
}

func (m model) statusLineTone(line string) string {
	trimmed := strings.TrimSpace(line)
	lowered := strings.ToLower(trimmed)

	switch {
	case strings.HasPrefix(trimmed, "Error:"),
		strings.HasPrefix(trimmed, "[fail]"),
		strings.HasPrefix(trimmed, "Fail "):
		return "error"
	case strings.HasPrefix(trimmed, "[ok]"),
		strings.HasPrefix(trimmed, "Started "),
		strings.HasPrefix(trimmed, "Reset complete"),
		strings.HasPrefix(trimmed, "Baseline ready"),
		strings.HasPrefix(trimmed, "SSH session opened"),
		strings.HasPrefix(trimmed, "Repo: available"),
		strings.HasPrefix(trimmed, "Result: complete"):
		return "success"
	case strings.HasPrefix(trimmed, "Warning:"),
		strings.HasPrefix(trimmed, "Result: incomplete"),
		strings.HasPrefix(trimmed, "Repo: unavailable"),
		strings.Contains(lowered, "virtualbox is busy"),
		strings.Contains(lowered, "timed out"),
		strings.Contains(lowered, "stale virtualbox disk"),
		strings.Contains(lowered, "child disk attached"):
		return "warning"
	case strings.HasPrefix(trimmed, "Use:"),
		strings.HasPrefix(trimmed, "A new PowerShell window was opened"):
		return "muted"
	case strings.HasPrefix(trimmed, "Lab:"),
		strings.HasPrefix(trimmed, "Progress check"),
		strings.HasPrefix(trimmed, "Simulator destroyed"),
		strings.HasPrefix(trimmed, "Lab destroyed"),
		strings.HasPrefix(trimmed, "Result:"),
		strings.HasPrefix(trimmed, "Repo:"):
		return "info"
	default:
		return "default"
	}
}

// ── Output summarisation ───────────────────────────────────

func summarizeActionOutput(output string) string {
	clean := StripAnsi(output)
	switch {
	case strings.Contains(clean, "LockMachine") || strings.Contains(clean, "lock request pending"):
		return "VirtualBox is busy\nWait a few seconds, then try the action again"
	case strings.Contains(clean, "timeout during server version negotiating"):
		return "SSH handshake timed out\nTry the action again once the VM finishes booting"
	case strings.Contains(clean, "VERR_ALREADY_EXISTS"):
		return "A stale VirtualBox disk is still registered\nRun destroy, then up, and try again"
	case strings.Contains(clean, "Cannot close medium"):
		return "VirtualBox still has a child disk attached\nRun destroy again after a few seconds"
	}

	lines := strings.Split(strings.TrimSpace(clean), "\n")
	filtered := make([]string, 0, len(lines))
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || trimmed == "Command returned a non-zero exit status." {
			continue
		}
		if matches := failLinePattern.FindStringSubmatch(trimmed); len(matches) >= 2 {
			label := summarizeCheckLabel(matches[1])
			filtered = append(filtered, fmt.Sprintf("[fail] %s", label))
			continue
		}
		if matches := failDetailPattern.FindStringSubmatch(trimmed); len(matches) >= 4 {
			label := summarizeCheckLabel(matches[3])
			filtered = append(filtered, fmt.Sprintf("Fail %s: [%s] %s", matches[1], matches[2], label))
			continue
		}
		if isSignificantLine(trimmed) {
			filtered = append(filtered, trimmed)
		}
	}

	if len(filtered) == 0 {
		if len(lines) > 0 {
			filtered = append(filtered, truncateLine(strings.TrimSpace(lines[0]), 140))
		}
		if len(lines) > 1 {
			filtered = append(filtered, truncateLine(strings.TrimSpace(lines[len(lines)-1]), 140))
		}
	}
	if len(filtered) > defaultMaxStatusLines {
		filtered = filtered[len(filtered)-defaultMaxStatusLines:]
	}
	return strings.Join(filtered, "\n")
}

func isSignificantLine(trimmed string) bool {
	significantPrefixes := []string{
		"Error:", "Use:", "Started ", "Reset complete", "Progress check",
		"SSH session opened", "Lab destroyed", "Simulator destroyed",
		"Baseline ready", "Result:", "Lab:", "A new PowerShell window was opened",
		"[fail]", "[ok]", "Fail ",
	}
	significantContains := []string{
		"VirtualBox is already locked", "already has a lock request pending",
		"LockMachine", "timeout during server version negotiating",
		"Cannot close medium", "VERR_ALREADY_EXISTS",
	}
	for _, p := range significantPrefixes {
		if strings.HasPrefix(trimmed, p) {
			return true
		}
	}
	for _, c := range significantContains {
		if strings.Contains(trimmed, c) {
			return true
		}
	}
	return false
}

func summarizeCheckLabel(command string) string {
	lowered := strings.ToLower(command)
	switch {
	case strings.Contains(lowered, "repomd.xml") || strings.Contains(lowered, "/etc/yum.repos.d") || strings.Contains(lowered, "dnf -q repolist") || strings.Contains(lowered, "baseos") || strings.Contains(lowered, "appstream"):
		return "repository check failed"
	case strings.Contains(lowered, "ls -zd /root") || strings.Contains(lowered, "admin_home_t") || strings.Contains(lowered, "restorecon") || strings.Contains(lowered, "autorelabel"):
		return "selinux relabel check failed"
	case strings.Contains(lowered, "passwordauthentication") || strings.Contains(lowered, "permitrootlogin") || strings.Contains(lowered, "/etc/ssh/sshd_config") || strings.Contains(lowered, "sshd -t"):
		return "ssh access check failed"
	case strings.Contains(lowered, "hostnamectl") || strings.Contains(lowered, "--static"):
		return "hostname check failed"
	case strings.Contains(lowered, "/etc/hosts") || strings.Contains(lowered, "getent hosts"):
		return "hosts entry check failed"
	case strings.Contains(lowered, "nmcli") || strings.Contains(lowered, "ipv4.addresses") || strings.Contains(lowered, "ipv4.gateway") || strings.Contains(lowered, "ipv4.dns") || strings.Contains(lowered, "ipv4.method") || strings.Contains(lowered, "connection.autoconnect"):
		return "network profile check failed"
	case strings.Contains(lowered, "systemctl"):
		return "service check failed"
	case strings.Contains(lowered, "firewall-cmd") || strings.Contains(lowered, "semanage") || strings.Contains(lowered, "getenforce"):
		return "security check failed"
	case strings.Contains(lowered, "podman") || strings.Contains(lowered, "container"):
		return "container check failed"
	case strings.Contains(lowered, "mount") || strings.Contains(lowered, "findmnt") || strings.Contains(lowered, "/etc/fstab") || strings.Contains(lowered, "swapon"):
		return "storage check failed"
	case strings.Contains(lowered, "useradd") || strings.Contains(lowered, "groupadd") || strings.Contains(lowered, "chage") || strings.Contains(lowered, "getent passwd"):
		return "user check failed"
	default:
		return "check failed"
	}
}

// ── Help overlay ───────────────────────────────────────────

func (m model) helpBody() string {
	return strings.Join([]string{
		"RHCSA Simulator — Keyboard Reference",
		"",
		"Navigation",
		"  Tab / Shift+Tab      move between the catalog and details",
		"  ← / →                switch LABS and EXAMS, or switch documents in details",
		"  ↑ / ↓ / j / k        move within the active pane",
		"  PgUp / PgDn          page through details",
		"  Ctrl+U / Ctrl+D      half-page scroll in details",
		"  g / G                jump to top / bottom of the active pane",
		"  Esc                  return to the catalog pane",
		"",
		"Actions",
		"  Enter / s            start selected lab or exam",
		"  c                    run checks (labs only)",
		"  r                    reset the active run",
		"  y                    copy checks or solution to the clipboard",
		"  z                    SSH → clientvm",
		"  x                    SSH → servervm",
		"",
		"Search",
		"  / or Ctrl+F          open search",
		"  Enter                keep filter",
		"  Esc                  clear filter",
		"",
		"Views",
		"  F1 / 1               Tasks",
		"  F2 / 2               Hint",
		"  F3 / 3 / \"           Checks",
		"  F4 / 4 / '           Solution",
		"",
		"Press ? or Esc to close this help.",
	}, "\n")
}
