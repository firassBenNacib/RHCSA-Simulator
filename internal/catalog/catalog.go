package catalog

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type LabPaths struct {
	Prompt   string `json:"prompt"`
	Hint     string `json:"hint"`
	Check    string `json:"check"`
	Solution string `json:"solution"`
	Metadata string `json:"metadata"`
}

type Lab struct {
	ID              string   `json:"id"`
	Title           string   `json:"title"`
	Description     string   `json:"description"`
	TimeLimitMinute int      `json:"time_limit_minutes"`
	ObjectiveTags   []string `json:"objective_tags"`
	RequiresServer  bool     `json:"requires_servervm"`
	Paths           LabPaths `json:"paths"`
	SourceManifest  string   `json:"source_manifest"`
}

type ExamPaths struct {
	Tasks    string `json:"tasks"`
	Solution string `json:"solution"`
}

type Exam struct {
	ID              string    `json:"id"`
	Title           string    `json:"title"`
	Description     string    `json:"description"`
	TimeLimitMinute int       `json:"time_limit_minutes"`
	ObjectiveTags   []string  `json:"objective_tags"`
	RequiresServer  bool      `json:"requires_servervm"`
	PasswordRecover bool      `json:"password_recovery"`
	SourceManifest  string    `json:"source_manifest"`
	Paths           ExamPaths `json:"paths"`
}

func Load(root string) ([]Lab, []Exam, error) {
	labsPath := filepath.Join(root, "exercises", "catalog.json")
	examsPath := filepath.Join(root, "exercises", "exams.json")

	labs, err := loadLabs(labsPath)
	if err != nil {
		return nil, nil, err
	}

	exams, err := loadExams(examsPath)
	if err != nil {
		return nil, nil, err
	}

	return labs, exams, nil
}

func ReadRelative(root, relative string) string {
	if relative == "" {
		return ""
	}

	content, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(relative)))
	if err != nil {
		return fmt.Sprintf("Unable to read %s\n\n%s", relative, err)
	}

	return string(content)
}

func loadLabs(path string) ([]Lab, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("load labs catalog: %w", err)
	}

	var labs []Lab
	if err := json.Unmarshal(raw, &labs); err != nil {
		return nil, fmt.Errorf("parse labs catalog: %w", err)
	}

	return labs, nil
}

func loadExams(path string) ([]Exam, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("load exams catalog: %w", err)
	}

	var exams []Exam
	if err := json.Unmarshal(raw, &exams); err != nil {
		return nil, fmt.Errorf("parse exams catalog: %w", err)
	}

	return exams, nil
}
