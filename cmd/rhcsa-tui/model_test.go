package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"rhcsa_exam_vms/internal/utils"
)

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

	got, _ := m.handleMouse(tea.MouseMsg{X: examsStart, Y: renderedMouseY(y), Type: tea.MouseLeft})
	updated := got.(model)
	if updated.activeTab != examsTab {
		t.Fatalf("expected exams tab after mouse click, got %v", updated.activeTab)
	}

	got, _ = updated.handleMouse(tea.MouseMsg{X: labsStart, Y: renderedMouseY(y), Type: tea.MouseLeft})
	updated = got.(model)
	if updated.activeTab != labsTab {
		t.Fatalf("expected labs tab after mouse click, got %v", updated.activeTab)
	}

	got, _ = updated.handleMouse(tea.MouseMsg{X: examsStart, Y: renderedMouseY(y + 1), Type: tea.MouseLeft})
	updated = got.(model)
	if updated.activeTab != labsTab {
		t.Fatalf("expected click below tab row to leave active tab unchanged, got %v", updated.activeTab)
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

	got, _ := m.handleMouse(tea.MouseMsg{X: hintBounds[0], Y: renderedMouseY(y), Type: tea.MouseLeft})
	updated := got.(model)
	if updated.detail != detailHint {
		t.Fatalf("expected hint detail after mouse click, got %v", updated.detail)
	}
	if updated.focus != focusDetail {
		t.Fatalf("expected detail focus after mouse click, got %v", updated.focus)
	}

	updated.detail = detailPrompt
	got, _ = updated.handleMouse(tea.MouseMsg{X: hintBounds[0], Y: renderedMouseY(y + 1), Type: tea.MouseLeft})
	updated = got.(model)
	if updated.detail != detailPrompt {
		t.Fatalf("expected click below detail tab row to leave detail unchanged, got %v", updated.detail)
	}
}

func TestMouseClickSelectsExpectedLabRow(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.labs = append(m.labs, m.labs[0])
	m.labs[1].ID = "lab-02-demo"
	m.labs[1].Title = "Lab 02: Second Demo"

	got, _ := m.handleMouse(tea.MouseMsg{X: 6, Y: renderedMouseY(5), Type: tea.MouseLeft})
	updated := got.(model)
	if updated.selectedLab != 1 {
		t.Fatalf("expected second lab to be selected from row click, got %d", updated.selectedLab)
	}
}

func footerBoundByID(t *testing.T, m model, id footerActionID) footerActionBound {
	t.Helper()
	for _, bound := range m.footerActionBounds(m.width) {
		if bound.id == id {
			return bound
		}
	}
	t.Fatalf("expected footer action %v", id)
	return footerActionBound{}
}

func clickFooterAction(m model, bound footerActionBound) (tea.Model, tea.Cmd) {
	x := (bound.startX + bound.endX) / 2
	return m.handleMouse(tea.MouseMsg{Type: tea.MouseLeft, X: x, Y: renderedMouseY(bound.y)})
}

func visibleTextPoint(t *testing.T, m model, target string) (int, int) {
	t.Helper()
	lines := strings.Split(utils.StripAnsi(m.View()), "\n")
	for y, line := range lines {
		idx := strings.Index(line, target)
		if idx < 0 {
			continue
		}
		return lipgloss.Width(line[:idx]) + lipgloss.Width(target)/2, y
	}
	t.Fatalf("expected visible target %q in view:\n%s", target, strings.Join(lines, "\n"))
	return 0, 0
}

func visibleTextEndPoint(t *testing.T, m model, target string) (int, int) {
	t.Helper()
	lines := strings.Split(utils.StripAnsi(m.View()), "\n")
	for y, line := range lines {
		idx := strings.Index(line, target)
		if idx < 0 {
			continue
		}
		return lipgloss.Width(line[:idx]) + lipgloss.Width(target) - 1, y
	}
	t.Fatalf("expected visible target %q in view:\n%s", target, strings.Join(lines, "\n"))
	return 0, 0
}

func clickVisibleText(m model, x, y int) (tea.Model, tea.Cmd) {
	return m.Update(tea.MouseMsg{Type: tea.MouseLeft, X: x, Y: y})
}

type rawMouseHarness struct {
	inner         model
	sawMouse      bool
	quitFromMouse bool
}

func (h rawMouseHarness) Init() tea.Cmd {
	return nil
}

func (h rawMouseHarness) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	mouse, ok := msg.(tea.MouseMsg)
	if !ok {
		return h, nil
	}

	next, cmd := h.inner.Update(mouse)
	h.inner = next.(model)
	h.sawMouse = true
	if commandContainsQuit(cmd) {
		h.quitFromMouse = true
	}
	return h, tea.Quit
}

func (h rawMouseHarness) View() string {
	return ""
}

func commandContainsQuit(cmd tea.Cmd) bool {
	if cmd == nil {
		return false
	}
	switch msg := cmd().(type) {
	case tea.QuitMsg:
		return true
	case tea.BatchMsg:
		for _, nested := range msg {
			if commandContainsQuit(nested) {
				return true
			}
		}
	}
	return false
}

func runRawSGRClick(t *testing.T, m model, x, y int) rawMouseHarness {
	t.Helper()

	input := fmt.Sprintf("\x1b[<0;%d;%dM", x+1, y+1)
	var output bytes.Buffer
	program := tea.NewProgram(
		rawMouseHarness{inner: m},
		tea.WithInput(strings.NewReader(input)),
		tea.WithOutput(&output),
		tea.WithoutRenderer(),
		tea.WithoutSignals(),
	)
	finalModel, err := program.Run()
	if err != nil {
		t.Fatalf("raw SGR click failed: %v", err)
	}
	final, ok := finalModel.(rawMouseHarness)
	if !ok {
		t.Fatalf("expected rawMouseHarness, got %T", finalModel)
	}
	if !final.sawMouse {
		t.Fatalf("expected raw SGR click at %d,%d to be parsed as a mouse event", x, y)
	}
	return final
}

func TestMouseClickFooterSwitchesDetailMode(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailPrompt

	got, _ := clickFooterAction(m, footerBoundByID(t, m, footerActionHints))
	updated := got.(model)
	if updated.detail != detailHint {
		t.Fatalf("expected footer F2 click to switch to hints, got %v", updated.detail)
	}

	got, _ = clickFooterAction(updated, footerBoundByID(t, updated, footerActionChecks))
	updated = got.(model)
	if updated.detail != detailCheck {
		t.Fatalf("expected footer F3 click to switch to checks, got %v", updated.detail)
	}
}

func TestMouseClickFooterSwitchesCatalogTabsBothWays(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 160
	m.height = 35
	m.focus = focusList
	m.activeTab = labsTab

	got, _ := clickFooterAction(m, footerBoundByID(t, m, footerActionSwitch))
	updated := got.(model)
	if updated.activeTab != examsTab {
		t.Fatalf("expected footer L/E click to switch to exams, got %v", updated.activeTab)
	}

	got, _ = clickFooterAction(updated, footerBoundByID(t, updated, footerActionSwitch))
	updated = got.(model)
	if updated.activeTab != labsTab {
		t.Fatalf("expected second footer L/E click to switch back to labs, got %v", updated.activeTab)
	}
}

func TestMouseClickFooterHelpAndQuitInLabMode(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 160
	m.height = 35
	m.activeTab = labsTab

	got, _ := clickFooterAction(m, footerBoundByID(t, m, footerActionHelp))
	updated := got.(model)
	if !updated.showHelp {
		t.Fatal("expected footer help click to open help in lab mode")
	}

	_, cmd := clickFooterAction(m, footerBoundByID(t, m, footerActionQuit))
	if cmd == nil {
		t.Fatal("expected footer quit click to return quit command in lab mode")
	}
}

func TestMouseClickVisibleFooterActionsInLabMode(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 160
	m.height = 35
	m.activeTab = labsTab
	m.focus = focusList

	x, y := visibleTextPoint(t, m, "/ Find")
	got, _ := clickVisibleText(m, x, y)
	updated := got.(model)
	if !updated.filterMode {
		t.Fatalf("expected visible / Find click to enter search mode at %d,%d", x, y)
	}

	x, y = visibleTextPoint(t, m, "? Help")
	got, _ = clickVisibleText(m, x, y)
	updated = got.(model)
	if !updated.showHelp {
		t.Fatalf("expected visible ? Help click to open help at %d,%d", x, y)
	}

	x, y = visibleTextPoint(t, m, "q Quit")
	_, cmd := clickVisibleText(m, x, y)
	if cmd == nil {
		t.Fatalf("expected visible q Quit click to return quit command at %d,%d", x, y)
	}

	x, y = visibleTextEndPoint(t, m, "q Quit")
	_, cmd = clickVisibleText(m, x+1, y)
	if cmd == nil {
		t.Fatalf("expected one-column-right q Quit click to return quit command at %d,%d", x+1, y)
	}
}

func TestMouseClickVisibleRepoLabFooterActionsThroughUpdate(t *testing.T) {
	m := buildRepoTestModel(t)
	m.activeTab = labsTab
	m.focus = focusList

	x, y := visibleTextPoint(t, m, "/ Find")
	got, _ := clickVisibleText(m, x, y)
	updated := got.(model)
	if !updated.filterMode {
		t.Fatalf("expected repository lab / Find click through Update to enter search mode at %d,%d", x, y)
	}

	x, y = visibleTextPoint(t, m, "? Help")
	got, _ = clickVisibleText(m, x, y)
	updated = got.(model)
	if !updated.showHelp {
		t.Fatalf("expected repository lab ? Help click through Update to open help at %d,%d", x, y)
	}

	x, y = visibleTextPoint(t, m, "q Quit")
	_, cmd := clickVisibleText(m, x, y)
	if cmd == nil {
		t.Fatalf("expected repository lab q Quit click through Update to return quit command at %d,%d", x, y)
	}
}

func TestRawSGRVisibleRepoLabFooterActions(t *testing.T) {
	m := buildRepoTestModel(t)
	m.width = 260
	m.height = 35
	m.activeTab = labsTab
	m.focus = focusList

	x, y := visibleTextPoint(t, m, "/ Find")
	if x <= 95 {
		t.Fatalf("expected / Find to be past the old X10 safe range, got x=%d", x)
	}
	got := runRawSGRClick(t, m, x, y).inner
	if !got.filterMode {
		t.Fatalf("expected raw SGR / Find click to enter search mode at %d,%d", x, y)
	}

	x, y = visibleTextPoint(t, m, "? Help")
	got = runRawSGRClick(t, m, x, y).inner
	if !got.showHelp {
		t.Fatalf("expected raw SGR ? Help click to open help at %d,%d", x, y)
	}

	x, y = visibleTextPoint(t, m, "q Quit")
	result := runRawSGRClick(t, m, x, y)
	if !result.quitFromMouse {
		t.Fatalf("expected raw SGR q Quit click to return quit command at %d,%d", x, y)
	}
}

func TestMouseClickFooterFindAndQuit(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 160
	m.height = 35

	got, _ := clickFooterAction(m, footerBoundByID(t, m, footerActionFind))
	updated := got.(model)
	if !updated.filterMode {
		t.Fatal("expected footer find click to enter search mode")
	}

	got, _ = clickFooterAction(updated, footerBoundByID(t, updated, footerActionFilterClear))
	updated = got.(model)
	if updated.filterMode {
		t.Fatal("expected footer clear click to leave search mode")
	}

	_, cmd := clickFooterAction(updated, footerBoundByID(t, updated, footerActionQuit))
	if cmd == nil {
		t.Fatal("expected footer quit click to return a quit command")
	}
}

func TestUppercaseActionKeysWork(t *testing.T) {
	m := buildRenderTestModel(t)
	if err := os.MkdirAll(filepath.Join(m.root, ".vagrant", "machines"), 0o755); err != nil {
		t.Fatal(err)
	}
	m.cachedActiveID = m.currentLab().ID

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

func TestSolutionCopyBoundsExistPerSection(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailSolution
	bounds := m.detailSectionCopyBounds()
	if len(bounds) == 0 {
		t.Fatal("expected solution copy bounds to be available")
	}
}

func TestPromptCopyBoundsAreHidden(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailPrompt
	bounds := m.detailSectionCopyBounds()
	if len(bounds) != 0 {
		t.Fatalf("expected task view copy bounds to be hidden, got %d", len(bounds))
	}
}

func captureClipboardCopy(t *testing.T) *string {
	t.Helper()
	var copied string
	original := clipboardCopy
	clipboardCopy = func(text string) error {
		copied = text
		return nil
	}
	t.Cleanup(func() {
		clipboardCopy = original
	})
	return &copied
}

func clickCopyBound(m model, bound sectionCopyBound) model {
	x := (bound.startX + bound.endX) / 2
	result, _ := m.handleMouse(tea.MouseMsg{Type: tea.MouseLeft, X: x, Y: renderedMouseY(bound.y)})
	return result.(model)
}

func renderedMouseY(renderedY int) int {
	return renderedY
}

func TestCheckCopyClickCopiesCommandBodyOnly(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailCheck
	copied := captureClipboardCopy(t)

	bounds := m.detailSectionCopyBounds()
	if len(bounds) == 0 {
		t.Fatal("expected check copy bounds")
	}

	updated := clickCopyBound(m, bounds[0])
	if !strings.Contains(updated.statusText, "Copied") {
		t.Fatalf("expected copied status, got %q", updated.statusText)
	}
	if *copied == "" {
		t.Fatal("expected clipboard content")
	}
	if strings.Contains(*copied, "Check 01") || strings.Contains(*copied, "Copy Section") {
		t.Fatalf("expected copied check body only, got %q", *copied)
	}
}

func TestSolutionCopyClickCopiesSectionBodyOnly(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailSolution
	copied := captureClipboardCopy(t)

	solutionPath := filepath.Join(m.root, "scenarios", "labs", "lab-01-demo", "LAB_SOLUTION.md")
	solutionBody := strings.Join([]string{
		"# Solution",
		"",
		"## Task 01 - First Task (client) - 10 pts",
		"",
		"```bash",
		"hostnamectl set-hostname demo",
		"nmcli con up demo",
		"```",
		"",
		"---",
		"",
		"## Task 02 - Second Task (client) - 10 pts",
		"",
		"```bash",
		"touch /root/second",
		"```",
	}, "\n")
	if err := os.WriteFile(solutionPath, []byte(solutionBody), 0o644); err != nil {
		t.Fatal(err)
	}

	bounds := m.detailSectionCopyBounds()
	if len(bounds) < 2 {
		t.Fatalf("expected at least two solution copy bounds, got %d", len(bounds))
	}

	updated := clickCopyBound(m, bounds[0])
	if !strings.Contains(updated.statusText, "Copied Task 01") {
		t.Fatalf("expected first task copied status, got %q", updated.statusText)
	}
	want := "hostnamectl set-hostname demo\nnmcli con up demo"
	if *copied != want {
		t.Fatalf("copied solution = %q, want %q", *copied, want)
	}
}

func TestSolutionCopyClickWorksWithGeneratedPreamble(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailSolution
	copied := captureClipboardCopy(t)

	solutionPath := filepath.Join(m.root, "scenarios", "labs", "lab-01-demo", "LAB_SOLUTION.md")
	solutionBody := strings.Join([]string{
		"# Lab 01: Networking And Hostname",
		"",
		"## Lab Solution",
		"## Overview",
		"| Field | Value |",
		"|---|---|",
		"| Scenario ID | `lab-01-networking-hostname` |",
		"| Mode | Lab |",
		"| Time limit | 35 minutes |",
		"| Objectives | networking-and-firewall |",
		"",
		"Configure persistent networking and hostname settings on client in RHCSA style.",
		"",
		"### Systems",
		"- client",
		"",
		"## General Instructions",
		"1. Unless a task states otherwise, make all changes persistent across reboots.",
		"",
		"## Task 01 - Client Network Configuration (client) - 10 pts",
		"",
		"```bash",
		"nmcli device status",
		"hostnamectl set-hostname client.netlab.local",
		"```",
		"",
		"---",
		"",
		"## Task 02 - Static Host Entry (client) - 10 pts",
		"",
		"```bash",
		"vim /etc/hosts",
		"192.168.122.3 repo.netlab.local",
		"```",
	}, "\n")
	if err := os.WriteFile(solutionPath, []byte(solutionBody), 0o644); err != nil {
		t.Fatal(err)
	}

	bounds := m.detailSectionCopyBounds()
	if len(bounds) < 2 {
		t.Fatalf("expected generated solution copy bounds, got %d", len(bounds))
	}

	updated := clickCopyBound(m, bounds[0])
	if !strings.Contains(updated.statusText, "Copied Task 01") {
		t.Fatalf("expected first generated task copied status, got %q", updated.statusText)
	}
	want := "nmcli device status\nhostnamectl set-hostname client.netlab.local"
	if *copied != want {
		t.Fatalf("copied generated solution = %q, want %q", *copied, want)
	}

	*copied = ""
	x, y := visibleTextEndPoint(t, m, "[COPY]")
	updatedModel, _ := clickVisibleText(m, x+1, y)
	updated = updatedModel.(model)
	if !strings.Contains(updated.statusText, "Copied Task 01") {
		t.Fatalf("expected one-column-right solution copy click to copy task at %d,%d, got status %q", x+1, y, updated.statusText)
	}
	if *copied != want {
		t.Fatalf("copied generated solution from one-column-right click = %q, want %q", *copied, want)
	}
}

func TestVisibleSolutionCopyClickWorksWithGeneratedPreamble(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailSolution
	copied := captureClipboardCopy(t)

	solutionPath := filepath.Join(m.root, "scenarios", "labs", "lab-01-demo", "LAB_SOLUTION.md")
	solutionBody := strings.Join([]string{
		"# Lab 01: Networking And Hostname",
		"",
		"## Lab Solution",
		"## Overview",
		"| Field | Value |",
		"|---|---|",
		"| Scenario ID | `lab-01-networking-hostname` |",
		"| Mode | Lab |",
		"| Time limit | 35 minutes |",
		"| Objectives | networking-and-firewall |",
		"",
		"Configure persistent networking and hostname settings on client in RHCSA style.",
		"",
		"### Systems",
		"- client",
		"",
		"## General Instructions",
		"1. Unless a task states otherwise, make all changes persistent across reboots.",
		"",
		"## Task 01 - Client Network Configuration (client) - 10 pts",
		"",
		"```bash",
		"nmcli device status",
		"hostnamectl set-hostname client.netlab.local",
		"```",
		"",
		"---",
		"",
		"## Task 02 - Static Host Entry (client) - 10 pts",
		"",
		"```bash",
		"vim /etc/hosts",
		"192.168.122.3 repo.netlab.local",
		"```",
	}, "\n")
	if err := os.WriteFile(solutionPath, []byte(solutionBody), 0o644); err != nil {
		t.Fatal(err)
	}

	x, y := visibleTextPoint(t, m, "[COPY]")
	updatedModel, _ := clickVisibleText(m, x, y)
	updated := updatedModel.(model)
	if !strings.Contains(updated.statusText, "Copied Task 01") {
		t.Fatalf("expected visible solution copy click to copy task at %d,%d, got status %q", x, y, updated.statusText)
	}
	want := "nmcli device status\nhostnamectl set-hostname client.netlab.local"
	if *copied != want {
		t.Fatalf("copied generated solution = %q, want %q", *copied, want)
	}
}

func TestVisibleRepoLabSolutionCopyClickThroughUpdate(t *testing.T) {
	m := buildRepoTestModel(t)
	m.detail = detailSolution
	copied := captureClipboardCopy(t)

	x, y := visibleTextPoint(t, m, "[COPY]")
	got, _ := clickVisibleText(m, x, y)
	updated := got.(model)
	if !strings.Contains(updated.statusText, "Copied Task 01") {
		t.Fatalf("expected repository solution [COPY] click through Update to copy task at %d,%d, got status %q", x, y, updated.statusText)
	}
	if !strings.Contains(*copied, "nmcli device status") {
		t.Fatalf("expected copied repository solution to contain command body, got %q", *copied)
	}
	if strings.Contains(*copied, "Task 01") {
		t.Fatalf("expected copied repository solution to omit title, got %q", *copied)
	}
}

func TestRawSGRVisibleRepoLabSolutionCopyClick(t *testing.T) {
	m := buildRepoTestModel(t)
	m.width = 260
	m.height = 35
	m.detail = detailSolution
	copied := captureClipboardCopy(t)

	x, y := visibleTextPoint(t, m, "[COPY]")
	if x <= 95 {
		t.Fatalf("expected solution [COPY] to be past the old X10 safe range, got x=%d", x)
	}
	got := runRawSGRClick(t, m, x, y).inner
	if !strings.Contains(got.statusText, "Copied Task 01") {
		t.Fatalf("expected raw SGR solution [COPY] click to copy task at %d,%d, got status %q", x, y, got.statusText)
	}
	if !strings.Contains(*copied, "nmcli device status") {
		t.Fatalf("expected copied repository solution to contain command body, got %q", *copied)
	}
	if strings.Contains(*copied, "Task 01") {
		t.Fatalf("expected copied repository solution to omit title, got %q", *copied)
	}
}

func TestCopyHitboxUsesExactVisibleRow(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.detail = detailSolution
	copied := captureClipboardCopy(t)

	bounds := m.detailSectionCopyBounds()
	if len(bounds) == 0 {
		t.Fatal("expected solution copy bounds")
	}
	x := (bounds[0].startX + bounds[0].endX) / 2

	result, _ := m.handleMouse(tea.MouseMsg{Type: tea.MouseLeft, X: x, Y: renderedMouseY(bounds[0].y - 1)})
	if *copied != "" {
		t.Fatalf("expected click above copy button not to copy, got %q", *copied)
	}
	if strings.Contains(result.(model).statusText, "Copied") {
		t.Fatalf("expected click above copy button not to report copy, got %q", result.(model).statusText)
	}

	result, _ = m.handleMouse(tea.MouseMsg{Type: tea.MouseLeft, X: x, Y: renderedMouseY(bounds[0].y)})
	if *copied == "" {
		t.Fatal("expected exact-row click to copy")
	}
	if !strings.Contains(result.(model).statusText, "Copied") {
		t.Fatalf("expected exact-row click to report copy, got %q", result.(model).statusText)
	}

	*copied = ""
	result, _ = m.handleMouse(tea.MouseMsg{Type: tea.MouseLeft, X: x, Y: renderedMouseY(bounds[0].y + 1)})
	if *copied != "" {
		t.Fatalf("expected click below copy button not to copy, got %q", *copied)
	}
	if strings.Contains(result.(model).statusText, "Copied") {
		t.Fatalf("expected click below copy button not to report copy, got %q", result.(model).statusText)
	}
}

func TestExamSolutionCopyClickCopiesClickedQuestion(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.activeTab = examsTab
	m.detail = detailSolution
	copied := captureClipboardCopy(t)

	solutionPath := filepath.Join(m.root, "scenarios", "exams", "mock-exam-a", "EXAM_SOLUTION.md")
	solutionBody := strings.Join([]string{
		"# Mock Exam A",
		"",
		"## Question 01 - First",
		"",
		"echo first",
		"",
		"## Question 02 - Second",
		"",
		"echo second",
	}, "\n")
	if err := os.WriteFile(solutionPath, []byte(solutionBody), 0o644); err != nil {
		t.Fatal(err)
	}

	bounds := m.detailSectionCopyBounds()
	if len(bounds) < 2 {
		t.Fatalf("expected at least two exam solution copy bounds, got %d", len(bounds))
	}

	updated := clickCopyBound(m, bounds[1])
	if !strings.Contains(updated.statusText, "Copied Question 02") {
		t.Fatalf("expected second question copied status, got %q", updated.statusText)
	}
	if *copied != "echo second" {
		t.Fatalf("copied exam solution = %q, want %q", *copied, "echo second")
	}
}

func TestMouseClickFooterTabPane(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 160
	m.height = 35
	m.focus = focusList

	got, _ := clickFooterAction(m, footerBoundByID(t, m, footerActionPane))
	updated := got.(model)
	if updated.focus != focusDetail {
		t.Fatalf("expected footer Tab Pane click to switch focus to detail, got %v", updated.focus)
	}

	got, _ = clickFooterAction(updated, footerBoundByID(t, updated, footerActionPane))
	updated = got.(model)
	if updated.focus != focusList {
		t.Fatalf("expected second footer Tab Pane click to switch focus back to list, got %v", updated.focus)
	}
}

func TestRawSGRClickTabPaneAndSwitch(t *testing.T) {
	m := buildRepoTestModel(t)
	m.width = 260
	m.height = 35
	m.focus = focusList
	m.activeTab = labsTab

	x, y := visibleTextPoint(t, m, "Tab Pane")
	got := runRawSGRClick(t, m, x, y)
	if got.inner.focus != focusDetail {
		t.Fatalf("expected raw SGR Tab Pane click at %d,%d to switch to detail focus, got %v", x, y, got.inner.focus)
	}

	x, y = visibleTextPoint(t, m, "←→ L/E")
	got = runRawSGRClick(t, m, x, y)
	if got.inner.activeTab != examsTab {
		t.Fatalf("expected raw SGR ←→ L/E click at %d,%d to switch to exams, got %v", x, y, got.inner.activeTab)
	}
}

func TestRawSGRClickCatalogTabsFromRenderedPosition(t *testing.T) {
	m := buildRepoTestModel(t)
	m.width = 260
	m.height = 35
	m.focus = focusList
	m.activeTab = labsTab

	x, y := visibleTextPoint(t, m, "EXAMS")
	got := runRawSGRClick(t, m, x, y)
	if got.inner.activeTab != examsTab {
		t.Fatalf("expected raw SGR EXAMS click at %d,%d to switch to exams tab, got %v", x, y, got.inner.activeTab)
	}
}

func TestRawSGRClickDetailTabsFromRenderedPosition(t *testing.T) {
	m := buildRepoTestModel(t)
	m.width = 260
	m.height = 35
	m.focus = focusList
	m.activeTab = labsTab
	m.detail = detailPrompt

	x, y := visibleTextPoint(t, m, "SOLUTIONS")
	got := runRawSGRClick(t, m, x, y)
	if got.inner.detail != detailSolution {
		t.Fatalf("expected raw SGR SOLUTIONS click at %d,%d to switch to solution mode, got %v", x, y, got.inner.detail)
	}
}

func TestMouseReleaseEventIgnored(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 160
	m.height = 35
	m.focus = focusList

	bound := footerBoundByID(t, m, footerActionPane)
	x := (bound.startX + bound.endX) / 2

	releaseMsg := tea.MouseMsg{Type: tea.MouseLeft, Action: tea.MouseActionRelease, X: x, Y: renderedMouseY(bound.y)}
	next, _ := m.handleMouse(releaseMsg)
	updated := next.(model)
	if updated.focus != m.focus {
		t.Fatalf("expected MouseRelease to be ignored (focus should stay %v), got %v", m.focus, updated.focus)
	}
}

func TestNavigationUpdateDoesNotForceClearScreen(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 160
	m.height = 35

	next, cmd := m.Update(tea.KeyMsg{Type: tea.KeyDown})
	updated := next.(model)
	if updated.selectedLab != 0 {
		t.Fatalf("expected single-item test catalog to keep selected lab at 0, got %d", updated.selectedLab)
	}
	if cmd != nil {
		t.Fatal("expected normal navigation to rely on Bubble Tea renderer without forcing a clear-screen command")
	}
}

func TestNoisyMouseEventsAreFilteredBeforeRender(t *testing.T) {
	for _, msg := range []tea.MouseMsg{
		{Type: tea.MouseMotion, X: 10, Y: 10},
		{Type: tea.MouseRelease, X: 10, Y: 10},
		{Type: tea.MouseLeft, Action: tea.MouseActionRelease, X: 10, Y: 10},
	} {
		if got := filterNoisyMouseEvents(nil, msg); got != nil {
			t.Fatalf("expected noisy mouse event %#v to be filtered, got %#v", msg, got)
		}
	}

	click := tea.MouseMsg{Type: tea.MouseLeft, Action: tea.MouseActionPress, X: 10, Y: 10}
	if got := filterNoisyMouseEvents(nil, click); got == nil {
		t.Fatal("expected mouse press to pass through the event filter")
	}
}

func TestRawSGRClickReleaseIgnored(t *testing.T) {
	m := buildRepoTestModel(t)
	m.width = 260
	m.height = 35
	m.focus = focusList
	m.activeTab = labsTab

	x, y := visibleTextPoint(t, m, "Tab Pane")
	input := fmt.Sprintf("\x1b[<0;%d;%dm", x+1, y+1)
	var output bytes.Buffer
	program := tea.NewProgram(
		rawMouseHarness{inner: m},
		tea.WithInput(strings.NewReader(input)),
		tea.WithOutput(&output),
		tea.WithoutRenderer(),
		tea.WithoutSignals(),
	)
	finalModel, err := program.Run()
	if err != nil {
		t.Fatalf("raw SGR release click failed: %v", err)
	}
	final, ok := finalModel.(rawMouseHarness)
	if !ok {
		t.Fatalf("expected rawMouseHarness, got %T", finalModel)
	}
	if final.inner.focus != m.focus {
		t.Fatalf("expected SGR release event to be ignored (focus should stay %v), got %v", m.focus, final.inner.focus)
	}
}

func TestHelpCloseButtonDismisses(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.showHelp = true

	sx, ex, y, ok := m.helpCloseBtnBounds()
	if !ok {
		t.Fatal("expected helpCloseBtnBounds to find the X button in rendered help view")
	}

	clickX := (sx + ex) / 2
	next, _ := m.Update(tea.MouseMsg{Type: tea.MouseLeft, X: clickX, Y: y})
	updated := next.(model)
	if updated.showHelp {
		t.Fatalf("expected clicking X to dismiss help, but showHelp still true")
	}
}

func TestHelpOverlayUsesProfessionalLayout(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.showHelp = true

	stripped := utils.StripAnsi(m.View())
	for _, want := range []string{
		"RHCSA Help",
		"Navigation",
		"Documents",
		" F1               Tasks",
		" F2               Hints",
		" F3               Checks",
		" F4               Solutions",
		"Actions",
		" z / x            SSH client / server",
	} {
		if !strings.Contains(stripped, want) {
			t.Fatalf("expected help overlay to contain %q, got:\n%s", want, stripped)
		}
	}
	if strings.Contains(stripped, "Mouse") {
		t.Fatalf("expected help overlay to omit mouse section, got:\n%s", stripped)
	}
}

func TestHelpCloseButtonMissDoesNotDismiss(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.showHelp = true

	next, _ := m.Update(tea.MouseMsg{Type: tea.MouseLeft, X: 0, Y: 0})
	updated := next.(model)
	if !updated.showHelp {
		t.Fatal("expected clicking outside X to keep help open")
	}
}

func TestRightClickDismissingHelp(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.showHelp = true

	next, _ := m.Update(tea.MouseMsg{Type: tea.MouseRight, X: 10, Y: 10})
	updated := next.(model)
	if updated.showHelp {
		t.Fatal("expected right-click to dismiss help overlay")
	}
}

func TestRightClickDismissesConfirm(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.confirmKind = "start"
	m.confirmText = "Start lab?"

	next, _ := m.Update(tea.MouseMsg{Type: tea.MouseRight, X: 10, Y: 10})
	updated := next.(model)
	if updated.confirmKind != "" {
		t.Fatal("expected right-click to dismiss confirm dialog")
	}
	if updated.statusText != "Cancelled" {
		t.Fatalf("expected statusText 'Cancelled', got %q", updated.statusText)
	}
}

func TestRightClickDismissesFilter(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.filterMode = true
	m.filterQuery = "net"

	next, _ := m.Update(tea.MouseMsg{Type: tea.MouseRight, X: 10, Y: 10})
	updated := next.(model)
	if !updated.filterMode {
		t.Fatal("expected first right-click to keep filter mode open (just clears query)")
	}
	if updated.filterQuery != "" {
		t.Fatalf("expected first right-click to clear filter query, got %q", updated.filterQuery)
	}

	next, _ = updated.Update(tea.MouseMsg{Type: tea.MouseRight, X: 10, Y: 10})
	updated = next.(model)
	if updated.filterMode {
		t.Fatal("expected second right-click to dismiss filter mode")
	}
}

func TestRightClickReturnsToList(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.focus = focusDetail

	next, _ := m.Update(tea.MouseMsg{Type: tea.MouseRight, X: 10, Y: 10})
	updated := next.(model)
	if updated.focus != focusList {
		t.Fatal("expected right-click in detail focus to return to list focus")
	}
}

func TestRightClickClearsStatusOutput(t *testing.T) {
	m := buildRenderTestModel(t)
	m.width = 120
	m.height = 35
	m.statusText = "All checks passed"

	next, _ := m.Update(tea.MouseMsg{Type: tea.MouseRight, X: 10, Y: 10})
	updated := next.(model)
	if updated.statusText != "" {
		t.Fatalf("expected right-click to clear status text, got %q", updated.statusText)
	}
}
