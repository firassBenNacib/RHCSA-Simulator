package main

import (
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
}
