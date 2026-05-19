package progress

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type ScenarioProgress struct {
	ViewedAt  string `json:"viewed_at,omitempty"`
	StartedAt string `json:"started_at,omitempty"`
	CheckedAt string `json:"checked_at,omitempty"`
	PassedAt  string `json:"passed_at,omitempty"`
}

type LabProgress = ScenarioProgress
type ExamProgress = ScenarioProgress

type State struct {
	Labs  map[string]*LabProgress  `json:"labs"`
	Exams map[string]*ExamProgress `json:"exams"`
}

func CompositeKey(track, id string) string {
	return track + "/" + id
}

func SplitCompositeKey(key string) (track, id string) {
	parts := strings.SplitN(key, "/", 2)
	if len(parts) == 2 {
		return parts[0], parts[1]
	}
	return "", parts[0]
}

func Load(path string) (*State, error) {
	dir, name := splitProgressPath(path)
	root, err := os.OpenRoot(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return &State{
				Labs:  map[string]*LabProgress{},
				Exams: map[string]*ExamProgress{},
			}, nil
		}
		return nil, err
	}
	defer func() {
		_ = root.Close()
	}()

	raw, err := root.ReadFile(name)
	if err != nil {
		if os.IsNotExist(err) {
			return &State{
				Labs:  map[string]*LabProgress{},
				Exams: map[string]*ExamProgress{},
			}, nil
		}
		return nil, err
	}

	var state State
	if err := json.Unmarshal(raw, &state); err != nil {
		return nil, err
	}

	if state.Labs == nil {
		state.Labs = map[string]*LabProgress{}
	}
	if state.Exams == nil {
		state.Exams = map[string]*ExamProgress{}
	}

	state.migrateFlatKeys()

	return &state, nil
}

func (s *State) Save(path string) error {
	if s.Labs == nil {
		s.Labs = map[string]*LabProgress{}
	}
	if s.Exams == nil {
		s.Exams = map[string]*ExamProgress{}
	}

	dir, name := splitProgressPath(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	root, err := os.OpenRoot(dir)
	if err != nil {
		return err
	}
	defer func() {
		_ = root.Close()
	}()

	payload, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}

	return root.WriteFile(name, append(payload, '\n'), 0o600)
}

func splitProgressPath(path string) (string, string) {
	dir := filepath.Dir(path)
	if dir == "" {
		dir = "."
	}
	return dir, filepath.Base(path)
}

func (s *State) Marker(id string) string {
	return progressMarker(s.ensure(id))
}

func (s *State) ExamMarker(id string) string {
	return progressMarker(s.ensureExam(id))
}

func progressMarker(item *ScenarioProgress) string {
	switch {
	case item.PassedAt != "":
		return "P"
	case item.CheckedAt != "":
		return "C"
	case item.StartedAt != "":
		return "S"
	default:
		return " "
	}
}

func (s *State) TouchViewed(id string) {
	touchViewed(s.ensure(id))
}

func (s *State) TouchExamViewed(id string) {
	touchViewed(s.ensureExam(id))
}

func touchViewed(item *ScenarioProgress) {
	if item.ViewedAt == "" {
		item.ViewedAt = now()
	}
}

func (s *State) TouchStarted(id string) {
	touchStarted(s.ensure(id))
}

func (s *State) TouchExamStarted(id string) {
	touchStarted(s.ensureExam(id))
}

func touchStarted(item *ScenarioProgress) {
	item.StartedAt = now()
	if item.ViewedAt == "" {
		item.ViewedAt = item.StartedAt
	}
}

func (s *State) TouchChecked(id string, passed bool) {
	item := s.ensure(id)
	item.CheckedAt = now()
	if passed {
		item.PassedAt = item.CheckedAt
	}
}

func (s *State) TouchExamChecked(id string, passed bool) {
	item := s.ensureExam(id)
	item.CheckedAt = now()
	if passed {
		item.PassedAt = item.CheckedAt
	}
}

func (s *State) ensure(id string) *LabProgress {
	if s.Labs == nil {
		s.Labs = map[string]*LabProgress{}
	}

	if _, ok := s.Labs[id]; !ok {
		s.Labs[id] = &LabProgress{}
	}

	return s.Labs[id]
}

func (s *State) ensureExam(id string) *ExamProgress {
	if s.Exams == nil {
		s.Exams = map[string]*ExamProgress{}
	}

	if _, ok := s.Exams[id]; !ok {
		s.Exams[id] = &ExamProgress{}
	}

	return s.Exams[id]
}

func now() string {
	return time.Now().Format(time.RFC3339)
}

func (s *State) migrateFlatKeys() {
	s.Labs = migrateMapKeys(s.Labs)
	s.Exams = migrateMapKeys(s.Exams)
}

func migrateMapKeys[T any](m map[string]*T) map[string]*T {
	updated := map[string]*T{}
	for key, value := range m {
		if strings.Contains(key, "/") {
			updated[key] = value
		}
	}
	for key, value := range m {
		if strings.Contains(key, "/") {
			continue
		}
		track, id := legacyFlatKeyTarget(key)
		composite := CompositeKey(track, id)
		if _, exists := updated[composite]; exists {
			continue
		}
		updated[composite] = value
	}
	return updated
}

func legacyFlatKeyTarget(key string) (track, id string) {
	if strings.HasPrefix(key, "rhcsa10-lab-") {
		return "rhcsa10", strings.TrimPrefix(key, "rhcsa10-")
	}
	if strings.HasPrefix(key, "rhcsa10-mock-exam-") {
		return "rhcsa10", key
	}
	if strings.HasPrefix(key, "rhcsa10-") {
		return "rhcsa10", strings.TrimPrefix(key, "rhcsa10-")
	}

	return "rhcsa9", key
}
