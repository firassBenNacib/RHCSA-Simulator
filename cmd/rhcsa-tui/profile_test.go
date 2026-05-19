package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolveTrackPreferenceDefaultsToRHCSA9(t *testing.T) {
	t.Setenv("RHCSA_TRACK", "")
	t.Setenv("RHCSA_PROFILE", "")

	root := t.TempDir()
	track, err := resolveTrackPreference("", root)
	if err != nil {
		t.Fatalf("resolveTrackPreference returned error: %v", err)
	}
	if track != "rhcsa9" {
		t.Fatalf("expected rhcsa9, got %q", track)
	}
}

func TestResolveTrackPreferenceUsesProjectProfile(t *testing.T) {
	t.Setenv("RHCSA_TRACK", "rhcsa9")
	t.Setenv("RHCSA_PROFILE", "rhel9")

	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, ".rhcsa-profile.json"), []byte("{\"profile\":\"rhel10\",\"track\":\"rhcsa10\"}"), 0o644); err != nil {
		t.Fatalf("write profile: %v", err)
	}

	track, err := resolveTrackPreference("", root)
	if err != nil {
		t.Fatalf("resolveTrackPreference returned error: %v", err)
	}
	if track != "rhcsa10" {
		t.Fatalf("expected rhcsa10, got %q", track)
	}
}

func TestResolveTrackPreferenceRespectsExplicitTrack(t *testing.T) {
	root := t.TempDir()
	track, err := resolveTrackPreference("all", root)
	if err != nil {
		t.Fatalf("resolveTrackPreference returned error: %v", err)
	}
	if track != "" {
		t.Fatalf("expected all-track empty marker, got %q", track)
	}
}

func TestResolveTrackPreferenceRejectsInvalidProjectProfile(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, ".rhcsa-profile.json"), []byte("{invalid"), 0o644); err != nil {
		t.Fatalf("write profile: %v", err)
	}

	if _, err := resolveTrackPreference("", root); err == nil {
		t.Fatal("expected invalid project profile to return an error")
	}
}

func TestResolveTrackPreferenceRejectsUnsupportedProjectProfile(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, ".rhcsa-profile.json"), []byte("{\"profile\":\"banana\"}"), 0o644); err != nil {
		t.Fatalf("write profile: %v", err)
	}

	if _, err := resolveTrackPreference("", root); err == nil {
		t.Fatal("expected unsupported project profile to return an error")
	}
}

func TestLoadProjectTimerDefault(t *testing.T) {
	root := t.TempDir()
	if loadProjectTimerDefault(root) {
		t.Fatal("expected missing profile to disable timer default")
	}
	if err := os.WriteFile(filepath.Join(root, ".rhcsa-profile.json"), []byte("{\"profile\":\"rhel9\",\"track\":\"rhcsa9\",\"timer_default_enabled\":true}"), 0o644); err != nil {
		t.Fatalf("write profile: %v", err)
	}
	if !loadProjectTimerDefault(root) {
		t.Fatal("expected timer default to load from project profile")
	}
}
