package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/firassBenNacib/RHCSA-Simulator/internal/catalog"
)

type projectProfileFile struct {
	Profile             string `json:"profile"`
	Track               string `json:"track"`
	TimerDefaultEnabled bool   `json:"timer_default_enabled"`
}

func resolveTrackPreference(requested, root string) (string, error) {
	if strings.TrimSpace(requested) != "" {
		return catalog.NormalizeTrack(requested), nil
	}

	if track, err := loadProjectTrack(root); err != nil {
		return "", err
	} else if track != "" {
		return track, nil
	}

	if value := os.Getenv("RHCSA_TRACK"); strings.TrimSpace(value) != "" {
		return catalog.NormalizeTrack(value), nil
	}

	if value := os.Getenv("RHCSA_PROFILE"); strings.TrimSpace(value) != "" {
		return projectProfileToTrack(value), nil
	}

	return "rhcsa10", nil
}

func loadProjectTrack(root string) (string, error) {
	path := filepath.Join(root, ".rhcsa-profile.json")
	// #nosec G304 -- the profile filename is fixed under the selected project root.
	raw, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return "", nil
		}
		return "", fmt.Errorf("read project profile: %w", err)
	}

	var state projectProfileFile
	if err := json.Unmarshal(raw, &state); err != nil {
		return "", fmt.Errorf("parse project profile: %w", err)
	}

	if track := catalog.NormalizeTrack(state.Track); track != "" {
		return track, nil
	}

	if strings.TrimSpace(state.Profile) != "" {
		track, ok := projectProfileToTrackStrict(state.Profile)
		if !ok {
			return "", fmt.Errorf("unsupported project profile %q", state.Profile)
		}
		return track, nil
	}

	return "", nil
}

func loadProjectTimerDefault(root string) bool {
	path := filepath.Join(root, ".rhcsa-profile.json")
	// #nosec G304 -- the profile filename is fixed under the selected project root.
	raw, err := os.ReadFile(path)
	if err != nil {
		return false
	}

	var state projectProfileFile
	if err := json.Unmarshal(raw, &state); err != nil {
		return false
	}
	return state.TimerDefaultEnabled
}

func projectProfileToTrack(value string) string {
	track, ok := projectProfileToTrackStrict(value)
	if !ok {
		return "rhcsa10"
	}
	return track
}

func projectProfileToTrackStrict(value string) (string, bool) {
	switch normalizeProjectProfileValue(value) {
	case "rhel9":
		return "rhcsa9", true
	case "rhel10":
		return "rhcsa10", true
	default:
		return "", false
	}
}

func normalizeProjectProfileValue(value string) string {
	normalized := strings.ToLower(strings.TrimSpace(value))
	normalized = strings.ReplaceAll(normalized, "-", "")
	normalized = strings.ReplaceAll(normalized, "_", "")
	switch normalized {
	case "", "10", "rhel10", "rhcsa10", "ex20010":
		return "rhel10"
	case "9", "rhel9", "rhcsa9", "ex2009":
		return "rhel9"
	default:
		return ""
	}
}
