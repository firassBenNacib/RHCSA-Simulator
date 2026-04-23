package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/firassBenNacib/rhcsa_exam_vms/internal/backend"
	"github.com/firassBenNacib/rhcsa_exam_vms/internal/catalog"
	"github.com/firassBenNacib/rhcsa_exam_vms/internal/progress"
)

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
	kind     string
	labID    string
	output   string
	err      error
	passed   bool
}

type model struct {
	root          string
	labs          []catalog.Lab
	exams         []catalog.Exam
	runner        *backend.Runner
	progress      *progress.State
	progressPath  string
	track         string
	theme         Theme

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

func newModel(root string, labs []catalog.Lab, exams []catalog.Exam, runner *backend.Runner, progressState *progress.State, progressPath string, track string) model {
	m := model{
		root:         root,
		labs:         labs,
		exams:        exams,
		runner:       runner,
		progress:     progressState,
		progressPath: progressPath,
		track:        catalog.NormalizeTrack(track),
		theme:        NewTheme(),
		activeTab:    labsTab,
		detail:       detailPrompt,
		focus:        focusList,
	}
	m.refreshActiveScenarioID()
	m.touchViewed()
	return m
}

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

func (m model) progressMarker(id string) string {
	if m.progress == nil {
		return " "
	}
	return m.progress.Marker(progress.CompositeKey(m.track, id))
}

func (m model) examProgressMarker(id string) string {
	if m.progress == nil {
		return " "
	}
	return m.progress.ExamMarker(progress.CompositeKey(m.track, id))
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
			m.progress.TouchViewed(progress.CompositeKey(m.track, lab.ID))
		}
	} else {
		if exam := m.currentExam(); exam.ID != "" {
			m.progress.TouchExamViewed(progress.CompositeKey(m.track, exam.ID))
		}
	}
}

func (m model) currentLab() catalog.Lab {
	labs := m.filteredLabs()
	if len(labs) == 0 {
		return catalog.Lab{}
	}
	return labs[clampInt(m.selectedLab, 0, len(labs)-1)]
}

func (m model) currentExam() catalog.Exam {
	exams := m.filteredExams()
	if len(exams) == 0 {
		return catalog.Exam{}
	}
	return exams[clampInt(m.selectedExam, 0, len(exams)-1)]
}

func (m model) currentScenarioID() string {
	if m.activeTab == labsTab {
		return m.currentLab().ID
	}
	return m.currentExam().ID
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

func (m *model) moveSelection(delta int) {
	if m.activeTab == labsTab {
		labs := m.filteredLabs()
		if len(labs) == 0 {
			return
		}
		m.selectedLab = clampInt(m.selectedLab+delta, 0, len(labs)-1)
	} else {
		exams := m.filteredExams()
		if len(exams) == 0 {
			return
		}
		m.selectedExam = clampInt(m.selectedExam+delta, 0, len(exams)-1)
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
		m.selectedLab = clampInt(m.selectedLab, 0, total-1)
	} else {
		total := len(m.filteredExams())
		if total == 0 {
			m.selectedExam = 0
			m.listOffset = 0
			return
		}
		m.selectedExam = clampInt(m.selectedExam, 0, total-1)
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

func (m model) trackLabel() string {
	switch catalog.NormalizeTrack(m.track) {
	case "rhcsa10":
		return "RHCSA 10"
	case "all":
		return "All tracks"
	default:
		return "RHCSA 9"
	}
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

func (m model) startConfirmText() string {
	if m.activeTab == labsTab {
		return fmt.Sprintf("Start %s? Click Start or press y/Enter to confirm.", m.currentLab().ID)
	}
	return fmt.Sprintf("Start %s? Click Start or press y/Enter to confirm.", m.currentExam().ID)
}

func (m model) startStatusText() string {
	if m.activeTab == labsTab {
		return fmt.Sprintf("Starting %s…", m.currentLab().ID)
	}
	return fmt.Sprintf("Starting %s…", m.currentExam().ID)
}

const helpCloseBtn = "X"

func (m model) helpBody() string {
	return strings.Join([]string{
		"RHCSA Help",
		"",
		"Navigation",
		"",
		" Tab              Switch pane",
		" Left / Right     Switch LABS/EXAMS or documents",
		" Up / Down        Move or scroll",
		" PgUp / PgDn      Jump by section",
		" g / G            Top / bottom",
		"",
		"Documents",
		"",
		" F1               Tasks",
		" F2               Hints",
		" F3               Checks",
		" F4               Solutions",
		"",
		"Actions",
		"",
		" Enter            Start selected item",
		" c                Check active lab",
		" r                Reset active run",
		" z / x            SSH client / server",
		" /                Find",
		" Esc              Close overlay or clear output",
		" q                Quit",
	}, "\n")
}
