package progress

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

type LabProgress struct {
	ViewedAt  string `json:"viewed_at,omitempty"`
	StartedAt string `json:"started_at,omitempty"`
	CheckedAt string `json:"checked_at,omitempty"`
	PassedAt  string `json:"passed_at,omitempty"`
}

type State struct {
	Labs map[string]*LabProgress `json:"labs"`
}

func Load(path string) (*State, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return &State{Labs: map[string]*LabProgress{}}, nil
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

	return &state, nil
}

func (s *State) Save(path string) error {
	if s.Labs == nil {
		s.Labs = map[string]*LabProgress{}
	}

	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}

	payload, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(path, append(payload, '\n'), 0o644)
}

func (s *State) Marker(id string) string {
	item := s.ensure(id)
	switch {
	case item.PassedAt != "":
		return "P"
	case item.CheckedAt != "":
		return "C"
	case item.StartedAt != "":
		return "S"
	case item.ViewedAt != "":
		return "."
	default:
		return " "
	}
}

func (s *State) TouchViewed(id string) {
	item := s.ensure(id)
	if item.ViewedAt == "" {
		item.ViewedAt = now()
	}
}

func (s *State) TouchStarted(id string) {
	item := s.ensure(id)
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

func (s *State) ensure(id string) *LabProgress {
	if s.Labs == nil {
		s.Labs = map[string]*LabProgress{}
	}

	if _, ok := s.Labs[id]; !ok {
		s.Labs[id] = &LabProgress{}
	}

	return s.Labs[id]
}

func now() string {
	return time.Now().Format(time.RFC3339)
}
