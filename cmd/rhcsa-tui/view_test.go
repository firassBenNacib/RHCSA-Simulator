package main

import (
	"strings"
	"testing"
)

func TestTruncateLine(t *testing.T) {
	tests := []struct {
		text  string
		width int
		want  string
	}{
		{"hello", 10, "hello"},
		{"hello world", 5, "hell…"},
		{"", 5, ""},
		{"abc", 0, ""},
		{"abc", 3, "abc"},
		{"abcd", 3, "ab…"},
		{"hi", 100, "hi"},
	}
	for _, tt := range tests {
		got := truncateLine(tt.text, tt.width)
		if got != tt.want {
			t.Errorf("truncateLine(%q, %d) = %q, want %q", tt.text, tt.width, got, tt.want)
		}
	}
}

func TestStripMarkdownBold(t *testing.T) {
	tests := []struct {
		input, want string
	}{
		{"**bold**", "bold"},
		{"no bold", "no bold"},
		{"**a** and **b**", "a and b"},
		{"", ""},
	}
	for _, tt := range tests {
		got := stripMarkdownBold(tt.input)
		if got != tt.want {
			t.Errorf("stripMarkdownBold(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestWrapLine(t *testing.T) {
	tests := []struct {
		line  string
		width int
		want  int // expected number of output lines
	}{
		{"hello", 80, 1},
		{"", 80, 1},
		{"a very long line that should wrap at some point eventually", 20, 3},
		{"  indented text", 80, 1},
	}
	for _, tt := range tests {
		got := wrapLine(tt.line, tt.width)
		if len(got) < tt.want {
			t.Errorf("wrapLine(%q, %d): got %d lines, want at least %d", tt.line, tt.width, len(got), tt.want)
		}
	}
}

func TestWrapLinePreservesIndent(t *testing.T) {
	lines := wrapLine("  hello world", 80)
	if len(lines) == 0 {
		t.Fatal("expected at least one line")
	}
	if !strings.HasPrefix(lines[0], "  ") {
		t.Errorf("expected leading indent, got %q", lines[0])
	}
}

func TestWrapLineNarrowWidth(t *testing.T) {
	lines := wrapLine("hello", 0)
	if len(lines) != 1 || lines[0] != "" {
		t.Errorf("wrapLine with width=0: got %v", lines)
	}
}

func TestSimplifyMarkdownTableLine(t *testing.T) {
	tests := []struct {
		input   string
		wantStr string
		wantOk  bool
	}{
		{"not a table", "", false},
		{"|---|---|", "", true},         // separator row
		{"| a | b |", "a: b", true},     // two-column
		{"| field | value |", "", true}, // header row — skip
		{"| x | y | z |", "x │ y │ z", true},
		{"|only|", "only", true},
	}
	for _, tt := range tests {
		gotStr, gotOk := simplifyMarkdownTableLine(tt.input)
		if gotOk != tt.wantOk {
			t.Errorf("simplifyMarkdownTableLine(%q) ok = %v, want %v", tt.input, gotOk, tt.wantOk)
		}
		if gotStr != tt.wantStr {
			t.Errorf("simplifyMarkdownTableLine(%q) = %q, want %q", tt.input, gotStr, tt.wantStr)
		}
	}
}

func TestMatchesPromptViewKey(t *testing.T) {
	// We can only test string-based matching since tea.KeyMsg requires internal state.
	// This test validates the function exists and handles basic cases.
	if matchesPromptViewKey(fakeKeyMsg("1")) != true {
		t.Error("expected '1' to match prompt view key")
	}
	if matchesPromptViewKey(fakeKeyMsg("q")) != false {
		t.Error("expected 'q' not to match prompt view key")
	}
}

func TestMatchesSolutionViewKey(t *testing.T) {
	if matchesSolutionViewKey(fakeKeyMsg("4")) != true {
		t.Error("expected '4' to match solution view key")
	}
	if matchesSolutionViewKey(fakeKeyMsg("q")) != false {
		t.Error("expected 'q' not to match solution view key")
	}
}

func TestMatchesCheckViewKey(t *testing.T) {
	if matchesCheckViewKey(fakeKeyMsg("3")) != true {
		t.Error("expected '3' to match check view key")
	}
	if matchesCheckViewKey(fakeKeyMsg("a")) != false {
		t.Error("expected 'a' not to match check view key")
	}
}

func TestNormalizeTerminalText(t *testing.T) {
	tests := []struct {
		input, want string
	}{
		{"hello", "hello"},
		{"Ã©", "é"},
		{"normal", "normal"},
	}
	for _, tt := range tests {
		got := normalizeTerminalText(tt.input)
		if got != tt.want {
			t.Errorf("normalizeTerminalText(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestAppendWrappedLinesEmpty(t *testing.T) {
	result := appendWrappedLines(nil, "   ", 80, NewTheme().DetailPlain)
	if len(result) != 1 || result[0] != "" {
		t.Errorf("expected single empty string for whitespace input, got %v", result)
	}
}
