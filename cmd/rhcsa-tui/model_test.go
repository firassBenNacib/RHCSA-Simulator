package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

// fakeKeyMsg creates a tea.KeyMsg for testing key matchers.
func fakeKeyMsg(s string) tea.KeyMsg {
	return tea.KeyMsg{
		Type:  tea.KeyRunes,
		Runes: []rune(s),
	}
}

func TestSummarizeActionOutputLockMachine(t *testing.T) {
	output := "Error: VirtualBox LockMachine failed"
	got := summarizeActionOutput(output)
	if !strings.Contains(got, "VirtualBox is busy") {
		t.Errorf("expected LockMachine summary, got %q", got)
	}
}

func TestSummarizeActionOutputTimeout(t *testing.T) {
	output := "Error: timeout during server version negotiating"
	got := summarizeActionOutput(output)
	if !strings.Contains(got, "SSH handshake timed out") {
		t.Errorf("expected timeout summary, got %q", got)
	}
}

func TestSummarizeActionOutputStale(t *testing.T) {
	output := "Error: VERR_ALREADY_EXISTS disk"
	got := summarizeActionOutput(output)
	if !strings.Contains(got, "stale VirtualBox disk") {
		t.Errorf("expected stale disk summary, got %q", got)
	}
}

func TestSummarizeActionOutputCloseMedium(t *testing.T) {
	output := "Error: Cannot close medium still attached"
	got := summarizeActionOutput(output)
	if !strings.Contains(got, "child disk attached") {
		t.Errorf("expected close medium summary, got %q", got)
	}
}

func TestSummarizeActionOutputPlainText(t *testing.T) {
	output := "Started lab-01-demo\nResult: complete (5/5)"
	got := summarizeActionOutput(output)
	if !strings.Contains(got, "Started lab-01-demo") {
		t.Errorf("expected significant lines preserved, got %q", got)
	}
}

func TestSummarizeActionOutputMaxLines(t *testing.T) {
	lines := make([]string, 20)
	for i := range lines {
		lines[i] = "[ok] test line"
	}
	output := strings.Join(lines, "\n")
	got := summarizeActionOutput(output)
	gotLines := strings.Split(got, "\n")
	if len(gotLines) > defaultMaxStatusLines {
		t.Errorf("expected max %d lines, got %d", defaultMaxStatusLines, len(gotLines))
	}
}

func TestSummarizeCheckLabel(t *testing.T) {
	tests := []struct {
		command string
		want    string
	}{
		{"grep repomd.xml", "repository check failed"},
		{"hostnamectl --static", "hostname check failed"},
		{"systemctl is-active httpd", "service check failed"},
		{"getenforce", "security check failed"},
		{"podman ps", "container check failed"},
		{"findmnt /mnt/data", "storage check failed"},
		{"getent passwd user1", "user check failed"},
		{"unknown command", "check failed"},
	}
	for _, tt := range tests {
		got := summarizeCheckLabel(tt.command)
		if got != tt.want {
			t.Errorf("summarizeCheckLabel(%q) = %q, want %q", tt.command, got, tt.want)
		}
	}
}

func TestIsSignificantLine(t *testing.T) {
	tests := []struct {
		line string
		want bool
	}{
		{"Error: something failed", true},
		{"[ok] test passed", true},
		{"[fail] test failed", true},
		{"Started lab-01", true},
		{"some random output", false},
		{"", false},
		{"Result: complete (5/5)", true},
		{"LockMachine failed", true},
	}
	for _, tt := range tests {
		got := isSignificantLine(tt.line)
		if got != tt.want {
			t.Errorf("isSignificantLine(%q) = %v, want %v", tt.line, got, tt.want)
		}
	}
}

func TestFilterItemsEmptyQuery(t *testing.T) {
	items := []string{"apple", "banana", "cherry"}
	result := filterItems(items, "", func(s string) string { return s })
	if len(result) != 3 {
		t.Errorf("expected 3 items for empty query, got %d", len(result))
	}
}

func TestFilterItemsMatches(t *testing.T) {
	items := []string{"apple", "banana", "cherry"}
	result := filterItems(items, "an", func(s string) string { return s })
	if len(result) != 1 || result[0] != "banana" {
		t.Errorf("expected [banana], got %v", result)
	}
}

func TestFilterItemsNoMatch(t *testing.T) {
	items := []string{"apple", "banana", "cherry"}
	result := filterItems(items, "xyz", func(s string) string { return s })
	if len(result) != 0 {
		t.Errorf("expected 0 items, got %d", len(result))
	}
}

func TestFilterItemsCaseInsensitive(t *testing.T) {
	items := []string{"Apple", "BANANA", "cherry"}
	result := filterItems(items, "APPLE", func(s string) string { return strings.ToLower(s) })
	if len(result) != 1 {
		t.Errorf("expected 1 item, got %d", len(result))
	}
}

func TestTabSwitchesPaneFocus(t *testing.T) {
	m := buildRenderTestModel(t)
	got, _ := m.handleNormalKey(tea.KeyMsg{Type: tea.KeyTab})
	updated := got.(model)
	if updated.focus != focusDetail {
		t.Fatalf("expected focusDetail after Tab, got %v", updated.focus)
	}
}

func TestDetailScrollIsIndependentPerDocument(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 18
	m.focus = focusDetail
	m.setCurrentDetailOffset(3)

	got, _ := m.handleNormalKey(fakeKeyMsg("4"))
	updated := got.(model)
	if updated.detail != detailSolution {
		t.Fatalf("expected solution view, got %v", updated.detail)
	}
	if updated.currentDetailOffset() != 0 {
		t.Fatalf("expected fresh solution offset to start at 0, got %d", updated.currentDetailOffset())
	}

	updated.setCurrentDetailOffset(2)
	got, _ = updated.handleNormalKey(fakeKeyMsg("1"))
	updated = got.(model)
	if updated.detail != detailPrompt {
		t.Fatalf("expected prompt view, got %v", updated.detail)
	}
	if updated.currentDetailOffset() != 3 {
		t.Fatalf("expected prompt offset to be preserved at 3, got %d", updated.currentDetailOffset())
	}
}

func TestListNavigationStopsScrollingWhenDetailFocused(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 14
	m.focus = focusDetail
	m.setCurrentDetailOffset(0)

	got, _ := m.handleNormalKey(tea.KeyMsg{Type: tea.KeyDown})
	updated := got.(model)
	if updated.selectedLab != 0 {
		t.Fatalf("expected selected lab to remain unchanged, got %d", updated.selectedLab)
	}
	if updated.currentDetailOffset() != 1 {
		t.Fatalf("expected detail offset to increase, got %d", updated.currentDetailOffset())
	}
}

func TestArrowKeysSwitchDocumentsWhenDetailFocused(t *testing.T) {
	m := buildRenderTestModel(t)
	m.focus = focusDetail
	m.detail = detailPrompt

	got, _ := m.handleNormalKey(tea.KeyMsg{Type: tea.KeyRight})
	updated := got.(model)
	if updated.detail != detailHint {
		t.Fatalf("expected hint view after right arrow, got %v", updated.detail)
	}

	got, _ = updated.handleNormalKey(tea.KeyMsg{Type: tea.KeyRight})
	updated = got.(model)
	if updated.detail != detailCheck {
		t.Fatalf("expected checks view after second right arrow, got %v", updated.detail)
	}

	got, _ = updated.handleNormalKey(tea.KeyMsg{Type: tea.KeyLeft})
	updated = got.(model)
	if updated.detail != detailHint {
		t.Fatalf("expected hint view after left arrow, got %v", updated.detail)
	}
}

func TestMouseClickSwitchesCatalogTabs(t *testing.T) {
	m := buildRenderTestModel(t)
	labsStart, labsEnd, examsStart, examsEnd, y := m.catalogTabBounds()
	if labsEnd < labsStart || examsEnd < examsStart {
		t.Fatal("expected valid tab bounds")
	}

	got, _ := m.handleMouse(tea.MouseMsg{X: examsStart, Y: y, Type: tea.MouseLeft})
	updated := got.(model)
	if updated.activeTab != examsTab {
		t.Fatalf("expected exams tab after mouse click, got %v", updated.activeTab)
	}

	got, _ = updated.handleMouse(tea.MouseMsg{X: labsStart, Y: y, Type: tea.MouseLeft})
	updated = got.(model)
	if updated.activeTab != labsTab {
		t.Fatalf("expected labs tab after mouse click, got %v", updated.activeTab)
	}

	got, _ = updated.handleMouse(tea.MouseMsg{X: examsStart, Y: y - 1, Type: tea.MouseLeft})
	updated = got.(model)
	if updated.activeTab != examsTab {
		t.Fatalf("expected exams tab after clicking the tab row above, got %v", updated.activeTab)
	}
}

func TestMouseClickSwitchesDetailTabs(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	bounds := m.detailTabBounds()
	hintBounds, ok := bounds[detailHint]
	if !ok {
		t.Fatal("expected hint tab bounds")
	}
	_, y := m.detailPaneOrigin()

	got, _ := m.handleMouse(tea.MouseMsg{X: hintBounds[0], Y: y, Type: tea.MouseLeft})
	updated := got.(model)
	if updated.detail != detailHint {
		t.Fatalf("expected hint detail after mouse click, got %v", updated.detail)
	}
	if updated.focus != focusDetail {
		t.Fatalf("expected detail focus after mouse click, got %v", updated.focus)
	}

	got, _ = updated.handleMouse(tea.MouseMsg{X: hintBounds[0], Y: y - 1, Type: tea.MouseLeft})
	updated = got.(model)
	if updated.detail != detailHint {
		t.Fatalf("expected hint detail after clicking the detail tab row above, got %v", updated.detail)
	}
}

func TestMouseClickSelectsExpectedLabRow(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.labs = append(m.labs, m.labs[0])
	m.labs[1].ID = "lab-02-demo"
	m.labs[1].Title = "Lab 02: Second Demo"

	got, _ := m.handleMouse(tea.MouseMsg{X: 6, Y: 5, Type: tea.MouseLeft})
	updated := got.(model)
	if updated.selectedLab != 1 {
		t.Fatalf("expected second lab to be selected from row click, got %d", updated.selectedLab)
	}
}

func TestUppercaseActionKeysWork(t *testing.T) {
	m := buildRenderTestModel(t)
	if err := os.MkdirAll(filepath.Join(m.root, ".vagrant", "machines"), 0o755); err != nil {
		t.Fatal(err)
	}

	got, _ := m.handleNormalKey(fakeKeyMsg("C"))
	updated := got.(model)
	if !updated.busy {
		t.Fatalf("expected uppercase C to trigger checks")
	}
}

func TestUppercaseQuitKeyWorks(t *testing.T) {
	m := buildRenderTestModel(t)
	got, cmd := m.handleNormalKey(fakeKeyMsg("Q"))
	if _, ok := got.(model); !ok {
		t.Fatal("expected model result")
	}
	if cmd == nil {
		t.Fatal("expected uppercase Q to return a quit command")
	}
}

func TestPageDownSnapsToNextDetailSection(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 14
	m.focus = focusDetail
	taskPath := filepath.Join(m.root, "scenarios", "labs", "lab-01-demo", "LAB_TASKS.md")
	taskBody := strings.Join([]string{
		"## Task 01 - First",
		"",
		"Do the first thing.",
		"",
		"## Task 02 - Second",
		"",
		"Do the second thing.",
		"",
		"## Task 03 - Third",
		"",
		"Do the third thing.",
	}, "\n")
	if err := os.WriteFile(taskPath, []byte(taskBody), 0o644); err != nil {
		t.Fatal(err)
	}

	got, _ := m.handleNormalKey(tea.KeyMsg{Type: tea.KeyPgDown})
	updated := got.(model)
	if updated.currentDetailOffset() <= 0 {
		t.Fatalf("expected page down to move to the next section, got offset %d", updated.currentDetailOffset())
	}
}

func TestExamQuestionsProduceSectionOffsets(t *testing.T) {
	m := buildRenderTestModel(t)
	m.activeTab = examsTab
	m.width = 120
	m.height = 18
	examTaskPath := filepath.Join(m.root, "scenarios", "exams", "mock-exam-a", "EXAM_TASKS.md")
	taskBody := strings.Join([]string{
		"# Mock Exam A",
		"",
		"## Question 01 - First",
		"",
		"Do the first thing.",
		"",
		"## Question 02 - Second",
		"",
		"Do the second thing.",
		"",
		"## Question 03 - Third",
		"",
		"Do the third thing.",
	}, "\n")
	if err := os.WriteFile(examTaskPath, []byte(taskBody), 0o644); err != nil {
		t.Fatal(err)
	}

	offsets := m.detailSectionOffsets()
	if len(offsets) < 3 {
		t.Fatalf("expected exam questions to create section offsets, got %v", offsets)
	}
}

func TestCopyDetailSectionOmitsHeadingTitle(t *testing.T) {
	m := buildRenderTestModel(t)
	m.detail = detailCheck
	sections := m.copyableSections()
	if len(sections) == 0 {
		t.Fatal("expected at least one copyable section")
	}
	if strings.Contains(sections[0].content, sections[0].title) {
		t.Fatalf("expected section copy payload to omit its title, got %q", sections[0].content)
	}
}
