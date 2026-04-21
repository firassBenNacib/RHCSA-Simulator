package progress

import "testing"

func TestProgressMarkerDoesNotRenderViewedDot(t *testing.T) {
	state := &State{Labs: map[string]*LabProgress{}, Exams: map[string]*ExamProgress{}}
	state.TouchViewed("lab-01")
	if got := state.Marker("lab-01"); got != " " {
		t.Fatalf("viewed-only marker = %q, want blank marker", got)
	}

	state.TouchStarted("lab-01")
	if got := state.Marker("lab-01"); got != "S" {
		t.Fatalf("started marker = %q, want S", got)
	}
}
