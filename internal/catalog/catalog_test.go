package catalog

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadBuildsCatalogFromScenarioManifests(t *testing.T) {
	root := t.TempDir()
	labRoot := filepath.Join(root, "scenarios", "labs", "lab-01-demo")
	examRoot := filepath.Join(root, "scenarios", "exams", "mock-exam-a")
	for _, path := range []string{labRoot, examRoot} {
		if err := os.MkdirAll(path, 0o755); err != nil {
			t.Fatalf("mkdir %s: %v", path, err)
		}
	}

	writeScenarioFile(t, filepath.Join(labRoot, "scenario.json"), `{
  "id": "lab-01-demo",
  "title": "Lab 01: Demo",
  "description": "Demo lab",
  "objective_tags": ["networking-and-firewall"],
  "supported_modes": ["lab"],
  "time_limit_minutes": 15,
  "flags": { "password_recovery": false, "requires_servervm": false },
  "content": { "lab": { "hints": ["Use nmcli"], "checks": ["grep -q demo /etc/hosts"] } }
}`)
	writeScenarioFile(t, filepath.Join(examRoot, "scenario.json"), `{
  "id": "mock-exam-a",
  "title": "Mock Exam A",
  "description": "Demo exam",
  "objective_tags": ["containers"],
  "supported_modes": ["exam"],
  "time_limit_minutes": 150,
  "flags": { "password_recovery": true, "requires_servervm": true },
  "content": { "lab": { "hints": [], "checks": [] } }
}`)
	writeScenarioFile(t, filepath.Join(labRoot, "LAB_TASKS.md"), "# Lab Tasks")
	writeScenarioFile(t, filepath.Join(labRoot, "LAB_SOLUTION.md"), "# Lab Solution")
	writeScenarioFile(t, filepath.Join(examRoot, "EXAM_TASKS.md"), "# Exam Tasks")
	writeScenarioFile(t, filepath.Join(examRoot, "EXAM_SOLUTION.md"), "# Exam Solution")

	labs, exams, err := Load(root)
	if err != nil {
		t.Fatalf("load catalog: %v", err)
	}

	if len(labs) != 1 {
		t.Fatalf("expected 1 lab, got %d", len(labs))
	}
	if len(exams) != 1 {
		t.Fatalf("expected 1 exam, got %d", len(exams))
	}

	if labs[0].TasksPath != "scenarios/labs/lab-01-demo/LAB_TASKS.md" {
		t.Fatalf("unexpected lab tasks path: %q", labs[0].TasksPath)
	}
	if labs[0].HintContent == "" || labs[0].CheckContent == "" {
		t.Fatalf("expected inline hint/check content to be populated")
	}
	if exams[0].TasksPath != "scenarios/exams/mock-exam-a/EXAM_TASKS.md" {
		t.Fatalf("unexpected exam tasks path: %q", exams[0].TasksPath)
	}
	if !exams[0].PasswordRecover || !exams[0].RequiresServer {
		t.Fatalf("expected exam flags to load from scenario manifest")
	}
}

func writeScenarioFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}
