package progress

import "testing"

func TestCompositeKey(t *testing.T) {
	got := CompositeKey("rhcsa9", "lab-01")
	want := "rhcsa9/lab-01"
	if got != want {
		t.Fatalf("CompositeKey = %q, want %q", got, want)
	}
}

func TestSplitCompositeKey(t *testing.T) {
	track, id := SplitCompositeKey("rhcsa10/mock-exam-a")
	if track != "rhcsa10" || id != "mock-exam-a" {
		t.Fatalf("SplitCompositeKey = %q, %q; want rhcsa10, mock-exam-a", track, id)
	}
	track, id = SplitCompositeKey("legacy-id")
	if track != "" || id != "legacy-id" {
		t.Fatalf("SplitCompositeKey(flat) = %q, %q; want empty, legacy-id", track, id)
	}
}

func TestProgressMarkerDoesNotRenderViewedDot(t *testing.T) {
	state := &State{Labs: map[string]*LabProgress{}, Exams: map[string]*ExamProgress{}}
	key := CompositeKey("rhcsa9", "lab-01")
	state.TouchViewed(key)
	if got := state.Marker(key); got != " " {
		t.Fatalf("viewed-only marker = %q, want blank marker", got)
	}

	state.TouchStarted(key)
	if got := state.Marker(key); got != "S" {
		t.Fatalf("started marker = %q, want S", got)
	}
}

func TestMigrateFlatKeys(t *testing.T) {
	state := &State{
		Labs:  map[string]*LabProgress{"lab-01": {StartedAt: "2026-01-01T00:00:00Z"}},
		Exams: map[string]*ExamProgress{"mock-exam-a": {ViewedAt: "2026-01-01T00:00:00Z"}},
	}
	state.migrateFlatKeys()
	if _, ok := state.Labs["lab-01"]; ok {
		t.Fatal("old flat key lab-01 should not exist after migration")
	}
	if _, ok := state.Labs["rhcsa9/lab-01"]; !ok {
		t.Fatal("migrated key rhcsa9/lab-01 should exist")
	}
	if _, ok := state.Exams["mock-exam-a"]; ok {
		t.Fatal("old flat key mock-exam-a should not exist after migration")
	}
	if _, ok := state.Exams["rhcsa9/mock-exam-a"]; !ok {
		t.Fatal("migrated key rhcsa9/mock-exam-a should exist")
	}
}

func TestMigratePreservesCompositeKeys(t *testing.T) {
	state := &State{
		Labs: map[string]*LabProgress{
			"rhcsa9/lab-01":  {StartedAt: "2026-01-01T00:00:00Z"},
			"rhcsa10/lab-01": {StartedAt: "2026-06-01T00:00:00Z"},
		},
	}
	state.migrateFlatKeys()
	if len(state.Labs) != 2 {
		t.Fatalf("expected 2 labs after migration, got %d", len(state.Labs))
	}
	if state.Labs["rhcsa9/lab-01"].StartedAt != "2026-01-01T00:00:00Z" {
		t.Fatal("rhcsa9/lab-01 should be preserved unchanged")
	}
	if state.Labs["rhcsa10/lab-01"].StartedAt != "2026-06-01T00:00:00Z" {
		t.Fatal("rhcsa10/lab-01 should be preserved unchanged")
	}
}
