package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/firassBenNacib/rhcsa_exam_vms/internal/backend"
	"github.com/firassBenNacib/rhcsa_exam_vms/internal/catalog"
	"github.com/firassBenNacib/rhcsa_exam_vms/internal/progress"
)

var version = "dev"

func main() {
	projectRoot := flag.String("project-root", "", "path to the RHCSA simulator repository")
	track := flag.String("track", "", "scenario track to show: rhcsa9, rhcsa10, or all")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Parse()

	if *showVersion {
		fmt.Printf("rhcsa-tui %s\n", version)
		return
	}

	root, err := findProjectRoot(*projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	resolvedTrack, err := resolveTrackPreference(*track, root)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error determining track: %v\n", err)
		os.Exit(1)
	}

	labs, exams, err := catalog.LoadTrack(root, resolvedTrack)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading catalog: %v\n", err)
		os.Exit(1)
	}

	runner, err := backend.New(root)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing backend: %v\n", err)
		os.Exit(1)
	}

	progressPath := filepath.Join(root, ".lab-state", "progress.json")
	progressState, err := progress.Load(progressPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading progress: %v\n", err)
		os.Exit(1)
	}

	model := newModel(root, labs, exams, runner, progressState, progressPath, resolvedTrack)

	p := tea.NewProgram(
		model,
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
		tea.WithFilter(filterNoisyMouseEvents),
	)

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error running TUI: %v\n", err)
		os.Exit(1)
	}
}

func filterNoisyMouseEvents(_ tea.Model, msg tea.Msg) tea.Msg {
	mouse, ok := msg.(tea.MouseMsg)
	if !ok {
		return msg
	}
	if mouse.Action == tea.MouseActionMotion || mouse.Action == tea.MouseActionRelease {
		return nil
	}
	return msg
}

func findProjectRoot(configured string) (string, error) {
	if configured != "" {
		if root, ok := searchForProjectRoot(configured); ok {
			return root, nil
		}
	}

	if configuredRoot := os.Getenv("RHCSA_SIMULATOR_ROOT"); configuredRoot != "" {
		if root, ok := searchForProjectRoot(configuredRoot); ok {
			return root, nil
		}
	}

	cwd, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("cannot get working directory: %w", err)
	}

	if root, ok := searchForProjectRoot(cwd); ok {
		return root, nil
	}

	if exePath, err := os.Executable(); err == nil {
		if root, ok := searchForProjectRoot(filepath.Dir(exePath)); ok {
			return root, nil
		}
	}

	return "", fmt.Errorf("RHCSA.ps1 marker file not found: searched %s, $RHCSA_SIMULATOR_ROOT, and executable directory", cwd)
}

func searchForProjectRoot(start string) (string, bool) {
	dir := start
	for {
		root, err := os.OpenRoot(dir)
		if err == nil {
			_, statErr := root.Stat("RHCSA.ps1")
			_ = root.Close()
			if statErr == nil {
				return dir, true
			}
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			return "", false
		}
		dir = parent
	}
}
