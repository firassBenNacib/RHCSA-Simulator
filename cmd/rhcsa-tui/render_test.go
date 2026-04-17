package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"rhcsa_exam_vms/internal/catalog"
	"rhcsa_exam_vms/internal/progress"
	"rhcsa_exam_vms/internal/utils"
)

func buildRenderTestModel(t *testing.T) model {
	t.Helper()

	root := t.TempDir()

	labRoot := filepath.Join(root, "scenarios", "labs", "lab-01-demo")
	examRoot := filepath.Join(root, "scenarios", "exams", "mock-exam-a")
	for _, p := range []string{labRoot, examRoot} {
		if err := os.MkdirAll(p, 0o755); err != nil {
			t.Fatal(err)
		}
	}

	longTasks := "# Lab Tasks\n\n- Configure hostname\n- Set up networking\n- Configure DNS\n- Validate connectivity\n- Reboot safely\n- Confirm persistence\n- Review logs\n- Verify route\n- Verify resolver\n- Document final state\n"
	longSolution := "# Solution\n\n```bash\nhostnamectl set-hostname demo\nnmcli con mod demo ipv4.addresses 192.168.122.50/24\nnmcli con up demo\n```\n\n- Verify with nmcli\n- Verify with ping\n- Verify with hostnamectl\n- Verify persistence after reboot\n"

	os.WriteFile(filepath.Join(labRoot, "scenario.json"), []byte(`{
		"id": "lab-01-demo", "title": "Lab 01: Networking and Hostname",
		"description": "Configure networking", "objective_tags": ["networking"],
		"supported_modes": ["lab"], "time_limit_minutes": 15,
		"flags": {"password_recovery": false, "requires_servervm": false},
		"content": {"lab": {"hints": ["Use nmcli"], "checks": ["grep -q demo /etc/hosts"]}}
	}`), 0o644)

	os.WriteFile(filepath.Join(examRoot, "scenario.json"), []byte(`{
		"id": "mock-exam-a", "title": "Mock Exam A: Full RHCSA",
		"description": "Full mock exam", "objective_tags": ["containers", "storage"],
		"supported_modes": ["exam"], "time_limit_minutes": 150,
		"flags": {"password_recovery": true, "requires_servervm": true},
		"content": {"lab": {"hints": [], "checks": []}}
	}`), 0o644)

	os.WriteFile(filepath.Join(labRoot, "LAB_TASKS.md"), []byte(longTasks), 0o644)
	os.WriteFile(filepath.Join(labRoot, "LAB_SOLUTION.md"), []byte(longSolution), 0o644)
	os.WriteFile(filepath.Join(examRoot, "EXAM_TASKS.md"), []byte("# Exam Tasks\n\n- Complete all tasks within time\n"), 0o644)
	os.WriteFile(filepath.Join(examRoot, "EXAM_SOLUTION.md"), []byte("# Solution\n\nSee lab solutions.\n"), 0o644)

	labs, exams, err := catalog.Load(root)
	if err != nil {
		t.Fatal(err)
	}

	progressState := &progress.State{
		Labs:  map[string]*progress.LabProgress{},
		Exams: map[string]*progress.ExamProgress{},
	}

	m := model{
		root:         root,
		labs:         labs,
		exams:        exams,
		progress:     progressState,
		progressPath: filepath.Join(root, "progress.json"),
		theme:        NewTheme(),
		activeTab:    labsTab,
		detail:       detailPrompt,
		focus:        focusList,
		width:        120,
		height:       35,
	}
	m.touchViewed()
	return m
}

// TestRenderFullView creates a model with sample data and renders the full view
// at a typical terminal size to verify no panics or layout glitches.
func TestRenderFullView(t *testing.T) {
	m := buildRenderTestModel(t)

	// Render wide layout
	output := m.View()
	if output == "" {
		t.Fatal("expected non-empty view output")
	}

	// Verify key elements are present
	stripped := utils.StripAnsi(output)

	checks := []string{
		"RHCSA Simulator", // header
		"LABS",            // tab
		"EXAMS",           // tab
		"TASKS",           // view mode
		"Lab 01",          // lab title
		"Start",           // footer key
		"Quit",            // footer key
	}

	for _, check := range checks {
		if !strings.Contains(stripped, check) {
			t.Errorf("expected view to contain %q", check)
		}
	}

	// Print the view for manual inspection
	fmt.Println("=== WIDE LAYOUT (120x35) ===")
	fmt.Println(output)

	// Render stacked layout (narrow terminal)
	m.width = 60
	m.height = 20
	narrow := m.View()
	if narrow == "" {
		t.Fatal("expected non-empty narrow view output")
	}

	fmt.Println("\n=== STACKED LAYOUT (60x20) ===")
	fmt.Println(narrow)

	// Switch to exams tab
	m.activeTab = examsTab
	m.width = 120
	m.height = 35
	examView := m.View()
	strippedExam := utils.StripAnsi(examView)
	if !strings.Contains(strippedExam, "Mock Exam A") {
		t.Error("expected exam tab to show Mock Exam A")
	}

	fmt.Println("\n=== EXAMS TAB (120x35) ===")
	fmt.Println(examView)

	// Test help overlay
	m.showHelp = true
	helpView := m.View()
	strippedHelp := utils.StripAnsi(helpView)
	if !strings.Contains(strippedHelp, "Keyboard Reference") {
		t.Error("expected help overlay to show keyboard reference")
	}

	// Test filter mode
	m.showHelp = false
	m.filterMode = true
	m.filterQuery = "network"
	filterView := m.View()
	strippedFilter := utils.StripAnsi(filterView)
	if !strings.Contains(strippedFilter, "network") {
		t.Error("expected filter mode to show search query")
	}

	// Test status text
	m.filterMode = false
	m.activeTab = labsTab // Switch back
	m.statusText = "Started lab-01-demo\nResult: complete (1/1)"
	statusView := m.View()
	strippedStatus := utils.StripAnsi(statusView)
	if !strings.Contains(strippedStatus, "Started lab-01-demo") {
		t.Error("expected status text to appear in output panel")
	}
}

// TestRenderZeroSize verifies View handles zero-size gracefully.
func TestRenderZeroSize(t *testing.T) {
	m := model{
		theme: NewTheme(),
	}
	output := m.View()
	if !strings.Contains(output, "Loading") {
		t.Errorf("expected loading message for zero size, got %q", output)
	}
}

func TestRenderRemovesLegacyScrollHintsAndTimePrefixes(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 20

	stripped := utils.StripAnsi(m.View())
	legacySnippets := []string{"more above", "more below", "scroll up()", "scroll up", "15m  Lab"}
	for _, snippet := range legacySnippets {
		if strings.Contains(stripped, snippet) {
			t.Fatalf("expected view to omit %q, got:\n%s", snippet, stripped)
		}
	}
}

func TestRenderFooterIncludesFunctionShortcutsForLabs(t *testing.T) {
	m := buildRenderTestModel(t)
	stripped := utils.StripAnsi(m.View())
	for _, snippet := range []string{"c", "Check", "F1", "Tasks", "F2", "Hints", "F3", "Checks", "F4", "Solutions", "q", "Quit"} {
		if !strings.Contains(stripped, snippet) {
			t.Fatalf("expected footer to contain %q, got:\n%s", snippet, stripped)
		}
	}
	if !strings.Contains(stripped, "1 / 1") {
		t.Fatalf("expected header to contain selection progress, got:\n%s", stripped)
	}
	if strings.Contains(stripped, "y Copy") {
		t.Fatalf("expected footer to omit y Copy, got:\n%s", stripped)
	}
	if !(strings.Index(stripped, "c Check") < strings.Index(stripped, "F1 Tasks")) {
		t.Fatalf("expected c Check before F1 Tasks, got:\n%s", stripped)
	}
	if !(strings.Index(stripped, "/ Find") < strings.Index(stripped, "? Help") &&
		strings.Index(stripped, "? Help") < strings.Index(stripped, "q Quit")) {
		t.Fatalf("expected footer to end with Find, Help, Quit ordering, got:\n%s", stripped)
	}
}

func TestSanitizeScenarioDocumentDropsOverviewNoise(t *testing.T) {
	description := "Configure persistent networking on clientvm in RHCSA style"
	body := strings.Join([]string{
		"## Overview",
		"| Field | Value |",
		"|---|---|",
		"| Scenario ID | `lab-01` |",
		"| Mode | Lab |",
		"| Time limit | 35 minutes |",
		"| Objectives | networking-and-firewall |",
		"",
		"Configure persistent networking on clientvm in RHCSA style.",
		"",
		"## Task 01",
		"Do the work.",
	}, "\n")

	sanitized := sanitizeScenarioDocument(description, body)
	for _, unwanted := range []string{"Overview", "Scenario ID", "networking-and-firewall", "in RHCSA style"} {
		if strings.Contains(sanitized, unwanted) {
			t.Fatalf("expected sanitized content to omit %q, got:\n%s", unwanted, sanitized)
		}
	}
	if !strings.Contains(sanitized, "## Task 01") {
		t.Fatalf("expected sanitized content to retain task heading, got:\n%s", sanitized)
	}
}

func TestTrimActionSectionBoilerplateRemovesSystemsAndGeneralInstructions(t *testing.T) {
	body := strings.Join([]string{
		"### Systems",
		"- clientvm",
		"- servervm",
		"",
		"## General Instructions",
		"1. Keep it persistent.",
		"2. Use standard tools.",
		"",
		"## Task 01",
		"```bash",
		"useradd demo",
		"```",
	}, "\n")

	trimmed := trimActionSectionBoilerplate(body)
	for _, unwanted := range []string{"### Systems", "General Instructions", "clientvm"} {
		if strings.Contains(trimmed, unwanted) {
			t.Fatalf("expected trimmed action body to omit %q, got:\n%s", unwanted, trimmed)
		}
	}
	if !strings.Contains(trimmed, "## Task 01") {
		t.Fatalf("expected trimmed action body to keep task content, got:\n%s", trimmed)
	}
}

func TestExtractSystemsFromDocument(t *testing.T) {
	body := strings.Join([]string{
		"### Systems",
		"- clientvm",
		"- servervm",
		"",
		"## Task 01",
		"Do the work.",
	}, "\n")

	systems := extractSystemsFromDocument(body)
	if got := strings.Join(systems, ", "); got != "clientvm, servervm" {
		t.Fatalf("expected systems list, got %q", got)
	}
}

func TestSolutionViewShowsCopyButtonAndTrimmedBoilerplate(t *testing.T) {
	m := buildRenderTestModel(t)
	m.detail = detailSolution

	stripped := utils.StripAnsi(m.View())
	if !strings.Contains(stripped, "[COPY]") {
		t.Fatalf("expected solution view to show [COPY], got:\n%s", stripped)
	}
	for _, unwanted := range []string{"Systems", "General Instructions"} {
		if strings.Contains(stripped, unwanted) {
			t.Fatalf("expected solution view to trim %q, got:\n%s", unwanted, stripped)
		}
	}
}

func TestPromptViewTrimsBoilerplateAndShowsTaskSooner(t *testing.T) {
	m := buildRenderTestModel(t)
	stripped := utils.StripAnsi(m.View())

	for _, unwanted := range []string{"Systems", "General Instructions"} {
		if strings.Contains(stripped, unwanted) {
			t.Fatalf("expected prompt view to trim %q, got:\n%s", unwanted, stripped)
		}
	}
	if !strings.Contains(stripped, "Configure hostname") {
		t.Fatalf("expected prompt view to keep actionable task content, got:\n%s", stripped)
	}
}

func TestSolutionRenderingUsesTerminalPromptStyle(t *testing.T) {
	m := buildRenderTestModel(t)
	m.detail = detailSolution
	rendered := utils.StripAnsi(m.renderDetailBody())
	if !strings.Contains(rendered, "$ hostnamectl set-hostname demo") {
		t.Fatalf("expected solution rendering to prefix commands with $, got:\n%s", rendered)
	}
}

func TestWideLayoutKeepsDetailFlushWithSeparator(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35

	lines := strings.Split(utils.StripAnsi(m.View()), "\n")
	if len(lines) < 6 {
		t.Fatalf("expected wide layout output, got:\n%s", m.View())
	}
	if !strings.Contains(lines[3], "1 / 1│  TASKS") {
		t.Fatalf("expected detail tabs to start at the separator, got:\n%s", lines[3])
	}
	if !strings.Contains(lines[5], "│  Lab 01: Networking and Hostname") {
		t.Fatalf("expected detail title to sit just after the separator, got:\n%s", lines[5])
	}
}
