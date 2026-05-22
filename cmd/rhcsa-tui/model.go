package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/firassBenNacib/RHCSA-Simulator/internal/backend"
	"github.com/firassBenNacib/RHCSA-Simulator/internal/catalog"
	"github.com/firassBenNacib/RHCSA-Simulator/internal/progress"
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
	kind   string
	labID  string
	track  string
	output string
	err    error
	passed bool
}

type uiTickMsg time.Time

type model struct {
	root         string
	labs         []catalog.Lab
	exams        []catalog.Exam
	runner       *backend.Runner
	progress     *progress.State
	progressPath string
	track        string
	theme        Theme

	activeTab              tabName
	detail                 detailMode
	focus                  paneFocus
	selectedLab            int
	selectedExam           int
	listOffset             int
	detailOffsets          [4]int
	width                  int
	height                 int
	statusText             string
	showHelp               bool
	busy                   bool
	actionStarted          time.Time
	confirmKind            string
	confirmText            string
	filterMode             bool
	filterQuery            string
	cachedActiveID         string
	cachedActiveMode       string
	cachedStartedAt        time.Time
	cachedEndsAt           time.Time
	cachedTimeLimitMinutes int
	timerDefaultEnabled    bool
	timerEnabled           bool
	timerEndsAt            time.Time
	now                    time.Time
	lastListClickTab       tabName
	lastListClickIndex     int
	lastListClickAt        time.Time
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
		now:          time.Now(),
	}
	m.timerDefaultEnabled = loadProjectTimerDefault(root)
	m.refreshActiveScenarioID()
	if m.timerDefaultEnabled && m.activeScenarioID() != "" {
		m.timerEnabled = true
		m.timerEndsAt = m.timerStartDeadline()
	}
	m.touchViewed()
	return m
}

func (m *model) refreshActiveScenarioID() {
	type activeScenario struct {
		StartedAt string `json:"started_at"`
		EndsAt    string `json:"ends_at"`
		Mode      string `json:"mode"`
		Scenario  struct {
			ID               string `json:"id"`
			TimeLimitMinutes int    `json:"time_limit_minutes"`
		} `json:"scenario"`
	}

	raw, err := os.ReadFile(filepath.Join(m.root, ".lab-state", "active-run.json"))
	if err != nil {
		m.cachedActiveID = ""
		m.cachedActiveMode = ""
		m.cachedStartedAt = time.Time{}
		m.cachedEndsAt = time.Time{}
		m.cachedTimeLimitMinutes = 0
		return
	}

	var state activeScenario
	if err := json.Unmarshal(raw, &state); err != nil {
		m.cachedActiveID = ""
		m.cachedActiveMode = ""
		m.cachedStartedAt = time.Time{}
		m.cachedEndsAt = time.Time{}
		m.cachedTimeLimitMinutes = 0
		return
	}
	m.cachedActiveID = state.Scenario.ID
	m.cachedActiveMode = strings.ToLower(strings.TrimSpace(state.Mode))
	m.cachedTimeLimitMinutes = state.Scenario.TimeLimitMinutes
	if startedAt, err := time.Parse(time.RFC3339Nano, state.StartedAt); err == nil {
		m.cachedStartedAt = startedAt
	} else {
		m.cachedStartedAt = time.Time{}
	}
	if endsAt, err := time.Parse(time.RFC3339Nano, state.EndsAt); err == nil {
		m.cachedEndsAt = endsAt
	} else {
		m.cachedEndsAt = time.Time{}
	}
}

func (m model) activeRunPath() string {
	return filepath.Join(m.root, ".lab-state", "active-run.json")
}

func (m *model) restartActiveRunTimer(now time.Time) (time.Time, error) {
	raw, err := os.ReadFile(m.activeRunPath())
	if err != nil {
		return time.Time{}, err
	}

	var state map[string]interface{}
	if err := json.Unmarshal(raw, &state); err != nil {
		return time.Time{}, err
	}

	minutes := activeRunTimeLimitMinutes(state)
	if minutes <= 0 {
		return time.Time{}, fmt.Errorf("active run has no time limit")
	}

	startedAt := now
	endsAt := startedAt.Add(time.Duration(minutes) * time.Minute)
	state["started_at"] = startedAt.Format(time.RFC3339Nano)
	state["ends_at"] = endsAt.Format(time.RFC3339Nano)

	content, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return time.Time{}, err
	}
	content = append(content, '\n')
	if err := os.WriteFile(m.activeRunPath(), content, 0o600); err != nil {
		return time.Time{}, err
	}

	m.refreshActiveScenarioID()
	return endsAt, nil
}

func activeRunTimeLimitMinutes(state map[string]interface{}) int {
	scenario, ok := state["scenario"].(map[string]interface{})
	if !ok {
		return 0
	}

	switch value := scenario["time_limit_minutes"].(type) {
	case float64:
		return int(value)
	case int:
		return value
	case json.Number:
		parsed, err := value.Int64()
		if err != nil {
			return 0
		}
		return int(parsed)
	default:
		return 0
	}
}

func (m model) activeScenarioID() string {
	return m.cachedActiveID
}

func (m model) activeScenarioMode() string {
	return m.cachedActiveMode
}

func preferredTrack(active string, tracks []string) string {
	if active != "" && active != "all" {
		return active
	}
	for _, track := range tracks {
		if track != "" && track != "all" {
			return track
		}
	}
	return "rhcsa9"
}

func (m model) progressKey(id string, tracks []string) string {
	return progress.CompositeKey(preferredTrack(m.track, tracks), id)
}

func (m model) progressMarker(id string, tracks []string) string {
	if m.progress == nil {
		return " "
	}
	return m.progress.Marker(m.progressKey(id, tracks))
}

func (m model) examProgressMarker(id string, tracks []string) string {
	if m.progress == nil {
		return " "
	}
	return m.progress.ExamMarker(m.progressKey(id, tracks))
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
			m.progress.TouchViewed(m.progressKey(lab.ID, lab.Tracks))
		}
	} else {
		if exam := m.currentExam(); exam.ID != "" {
			m.progress.TouchExamViewed(m.progressKey(exam.ID, exam.Tracks))
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

func (m model) scenarioTracksByID(id string) []string {
	for _, lab := range m.labs {
		if lab.ID == id {
			return append([]string{}, lab.Tracks...)
		}
	}
	for _, exam := range m.exams {
		if exam.ID == id {
			return append([]string{}, exam.Tracks...)
		}
	}
	return nil
}

func (m model) scenarioModeByID(id string) string {
	for _, lab := range m.labs {
		if lab.ID == id {
			return "lab"
		}
	}
	for _, exam := range m.exams {
		if exam.ID == id {
			return "exam"
		}
	}
	return ""
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
	if m.activeTab == examsTab && m.detail == detailHint {
		m.detail = detailPrompt
	}
}

func (m *model) setDetailMode(mode detailMode) {
	if m.activeTab == examsTab && mode == detailHint {
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
		return []detailMode{detailPrompt, detailCheck, detailSolution}
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
		return fmt.Sprintf("Start %s? Press y/Enter or click Start.", m.currentLab().ID)
	}
	return fmt.Sprintf("Start %s? Press y/Enter or click Start.", m.currentExam().ID)
}

func (m model) startStatusText() string {
	if m.activeTab == labsTab {
		lab := m.currentLab()
		if lab.Title != "" {
			return fmt.Sprintf("Starting %s", lab.Title)
		}
		return fmt.Sprintf("Starting %s", lab.ID)
	}
	exam := m.currentExam()
	if exam.Title != "" {
		return fmt.Sprintf("Starting %s", exam.Title)
	}
	return fmt.Sprintf("Starting %s", exam.ID)
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
		" c                Check active run",
		" r                Reset active run",
		" e                Exit active run",
		" t                Toggle timer",
		" z / x            SSH client / server",
		" /                Find",
		" Esc              Close overlay or clear output",
		" q                Quit",
	}, "\n")
}
