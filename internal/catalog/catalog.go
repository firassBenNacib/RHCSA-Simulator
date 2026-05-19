package catalog

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type Lab struct {
	ID              string
	Title           string
	Description     string
	TimeLimitMinute int
	Tracks          []string
	RHELMajor       int
	ObjectiveTags   []string
	RequiresServer  bool
	SourceManifest  string
	TasksPath       string
	SolutionPath    string
	HintContent     string
	CheckContent    string
}

type Exam struct {
	ID              string
	Title           string
	Description     string
	TimeLimitMinute int
	Tracks          []string
	RHELMajor       int
	ObjectiveTags   []string
	RequiresServer  bool
	PasswordRecover bool
	SourceManifest  string
	TasksPath       string
	SolutionPath    string
	CheckContent    string
}

type scenarioManifest struct {
	ID               string   `json:"id"`
	Title            string   `json:"title"`
	Description      string   `json:"description"`
	ObjectiveTags    []string `json:"objective_tags"`
	SupportedModes   []string `json:"supported_modes"`
	TimeLimitMinutes int      `json:"time_limit_minutes"`
	Tracks           []string `json:"tracks"`
	RHELMajor        int      `json:"rhel_major"`
	Flags            struct {
		RequiresServer   bool `json:"requires_server"`
		RequiresServervm bool `json:"requires_servervm"`
		PasswordRecovery bool `json:"password_recovery"`
	} `json:"flags"`
	Content struct {
		Lab struct {
			Hints  []string `json:"hints"`
			Checks []string `json:"checks"`
		} `json:"lab"`
		Exam struct {
			Checks []string `json:"checks"`
		} `json:"exam"`
	} `json:"content"`
}

func Load(root string) ([]Lab, []Exam, error) {
	return LoadTrack(root, "")
}

func LoadTrack(root, track string) ([]Lab, []Exam, error) {
	manifests, err := findScenarioManifests(root)
	if err != nil {
		return nil, nil, err
	}

	labs := make([]Lab, 0, len(manifests))
	exams := make([]Exam, 0, len(manifests))
	for _, manifestPath := range manifests {
		item, err := loadScenario(root, manifestPath)
		if err != nil {
			return nil, nil, err
		}
		if !scenarioMatchesTrack(item.tracks, track) {
			continue
		}
		if item.lab != nil {
			labs = append(labs, *item.lab)
		}
		if item.exam != nil {
			exams = append(exams, *item.exam)
		}
	}

	sort.Slice(labs, func(i, j int) bool { return labs[i].ID < labs[j].ID })
	sort.Slice(exams, func(i, j int) bool { return exams[i].ID < exams[j].ID })
	return labs, exams, nil
}

func ReadRelative(root, relative string) string {
	if relative == "" {
		return ""
	}

	rootFS, err := os.OpenRoot(root)
	if err != nil {
		return fmt.Sprintf("Unable to read %s\n\n%s", relative, err)
	}
	defer func() {
		_ = rootFS.Close()
	}()

	content, err := rootFS.ReadFile(filepath.FromSlash(relative))
	if err != nil {
		return fmt.Sprintf("Unable to read %s\n\n%s", relative, err)
	}

	return string(content)
}

type scenarioLoadResult struct {
	lab    *Lab
	exam   *Exam
	tracks []string
}

func findScenarioManifests(root string) ([]string, error) {
	scenariosRoot := filepath.Join(root, "scenarios")
	manifests := []string{}
	err := filepath.WalkDir(scenariosRoot, func(path string, d os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if d.IsDir() {
			return nil
		}
		if d.Name() == "scenario.json" {
			manifests = append(manifests, path)
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("load scenario manifests: %w", err)
	}
	return manifests, nil
}

func loadScenario(root, manifestPath string) (scenarioLoadResult, error) {
	relativeManifest, err := filepath.Rel(root, manifestPath)
	if err != nil {
		return scenarioLoadResult{}, fmt.Errorf("resolve manifest path %s: %w", manifestPath, err)
	}
	relativeManifest = filepath.ToSlash(relativeManifest)

	rootFS, err := os.OpenRoot(root)
	if err != nil {
		return scenarioLoadResult{}, fmt.Errorf("open catalog root %s: %w", root, err)
	}
	defer func() {
		_ = rootFS.Close()
	}()

	raw, err := rootFS.ReadFile(filepath.FromSlash(relativeManifest))
	if err != nil {
		return scenarioLoadResult{}, fmt.Errorf("read scenario manifest %s: %w", manifestPath, err)
	}

	var manifest scenarioManifest
	if err := json.Unmarshal(raw, &manifest); err != nil {
		return scenarioLoadResult{}, fmt.Errorf("parse scenario manifest %s: %w", manifestPath, err)
	}

	scenarioRoot := filepath.Dir(manifestPath)
	relativeTasks := func(name string) string {
		full := filepath.Join(scenarioRoot, name)
		rel, relErr := filepath.Rel(root, full)
		if relErr != nil {
			return ""
		}
		return filepath.ToSlash(rel)
	}

	result := scenarioLoadResult{}
	tracks := normalizeTracks(manifest.Tracks)
	rhelMajor := manifest.RHELMajor
	if rhelMajor == 0 {
		rhelMajor = 9
	}
	requiresServer := manifest.Flags.RequiresServer || manifest.Flags.RequiresServervm
	result.tracks = tracks
	modes := make(map[string]bool, len(manifest.SupportedModes))
	for _, mode := range manifest.SupportedModes {
		modes[strings.ToLower(strings.TrimSpace(mode))] = true
	}

	if modes["lab"] {
		result.lab = &Lab{
			ID:              manifest.ID,
			Title:           manifest.Title,
			Description:     manifest.Description,
			TimeLimitMinute: manifest.TimeLimitMinutes,
			Tracks:          append([]string{}, tracks...),
			RHELMajor:       rhelMajor,
			ObjectiveTags:   append([]string{}, manifest.ObjectiveTags...),
			RequiresServer:  requiresServer,
			SourceManifest:  relativeManifest,
			TasksPath:       relativeTasks("LAB_TASKS.md"),
			SolutionPath:    relativeTasks("LAB_SOLUTION.md"),
			HintContent:     renderHints(manifest.Title, manifest.Content.Lab.Hints),
			CheckContent:    renderChecks("lab", manifest.Content.Lab.Checks),
		}
	}

	if modes["exam"] {
		result.exam = &Exam{
			ID:              manifest.ID,
			Title:           manifest.Title,
			Description:     manifest.Description,
			TimeLimitMinute: manifest.TimeLimitMinutes,
			Tracks:          append([]string{}, tracks...),
			RHELMajor:       rhelMajor,
			ObjectiveTags:   append([]string{}, manifest.ObjectiveTags...),
			RequiresServer:  requiresServer,
			PasswordRecover: manifest.Flags.PasswordRecovery,
			SourceManifest:  relativeManifest,
			TasksPath:       relativeTasks("EXAM_TASKS.md"),
			SolutionPath:    relativeTasks("EXAM_SOLUTION.md"),
			CheckContent:    renderChecks("exam", manifest.Content.Exam.Checks),
		}
	}

	return result, nil
}

func normalizeTracks(values []string) []string {
	if len(values) == 0 {
		return []string{"rhcsa9"}
	}
	seen := map[string]bool{}
	tracks := make([]string, 0, len(values))
	for _, value := range values {
		track := NormalizeTrack(value)
		if track == "" || seen[track] {
			continue
		}
		seen[track] = true
		tracks = append(tracks, track)
	}
	if len(tracks) == 0 {
		return []string{"rhcsa9"}
	}
	return tracks
}

func NormalizeTrack(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	value = strings.ReplaceAll(value, "-", "")
	value = strings.ReplaceAll(value, "_", "")
	switch value {
	case "", "all":
		return ""
	case "9", "rhel9", "rhcsa9", "ex2009":
		return "rhcsa9"
	case "10", "rhel10", "rhcsa10", "ex20010":
		return "rhcsa10"
	default:
		return strings.ToLower(strings.TrimSpace(value))
	}
}

func scenarioMatchesTrack(tracks []string, requested string) bool {
	track := NormalizeTrack(requested)
	if track == "" {
		return true
	}
	for _, candidate := range normalizeTracks(tracks) {
		if candidate == track {
			return true
		}
	}
	return false
}

func renderHints(title string, hints []string) string {
	lines := []string{fmt.Sprintf("# %s Hints", title), ""}
	if len(hints) == 0 {
		lines = append(lines, "- No hints are defined for this lab.")
		return strings.Join(lines, "\n")
	}
	for _, hint := range hints {
		text := normalizeTaskText(hint)
		text = strings.TrimSuffix(text, ".")
		lines = append(lines, "- "+text+".")
	}
	return strings.Join(lines, "\n")
}

func renderChecks(kind string, checks []string) string {
	noun := "lab"
	if kind == "exam" {
		noun = "exam"
	}
	lines := []string{"# Automated Checks", "", fmt.Sprintf("Use `c Check` to test the active %s against these requirements.", noun), ""}
	if len(checks) == 0 {
		lines = append(lines, fmt.Sprintf("- No automated checks are defined for this %s.", noun))
		return strings.Join(lines, "\n")
	}
	for index, command := range checks {
		trimmed := strings.TrimSpace(command)
		target := "client"
		effective := trimmed
		if strings.HasPrefix(trimmed, "# server ") {
			target = "server"
			effective = strings.TrimPrefix(trimmed, "# server ")
		}
		lines = append(lines,
			fmt.Sprintf("## Check %02d [%s]", index+1, target),
			"- Expected: "+summarizeCheckExpectation(effective)+".",
			"- Target VM: "+target+".",
			"",
		)
	}
	return strings.TrimRight(strings.Join(lines, "\n"), "\n")
}

func summarizeCheckExpectation(command string) string {
	lowered := strings.ToLower(command)
	switch {
	case strings.Contains(lowered, "repomd.xml") || strings.Contains(lowered, "/etc/yum.repos.d") || strings.Contains(lowered, "dnf") || strings.Contains(lowered, "baseos") || strings.Contains(lowered, "appstream"):
		return "the package repository configuration is correct"
	case strings.Contains(lowered, "flatpak"):
		return "the Flatpak remote or application state is correct"
	case strings.Contains(lowered, "hostnamectl") || strings.Contains(lowered, "--static"):
		return "the static hostname is correct"
	case strings.Contains(lowered, "/etc/hosts") || strings.Contains(lowered, "getent hosts"):
		return "the required host name resolution entry is present"
	case strings.Contains(lowered, "nmcli") || strings.Contains(lowered, "ipv4.") || strings.Contains(lowered, "ipv6.") || strings.Contains(lowered, "connection.autoconnect"):
		return "the network profile is configured correctly"
	case strings.Contains(lowered, "passwordauthentication") || strings.Contains(lowered, "permitrootlogin") || strings.Contains(lowered, "/etc/ssh/sshd_config") || strings.Contains(lowered, "sshd -t") || strings.Contains(lowered, "authorized_keys") || strings.Contains(lowered, "ssh "):
		return "SSH access is configured as required"
	case strings.Contains(lowered, "restorecon") || strings.Contains(lowered, "ls -z") || strings.Contains(lowered, "httpd_sys_content_t") || strings.Contains(lowered, "admin_home_t"):
		return "the SELinux file context is correct"
	case strings.Contains(lowered, "setenforce") || strings.Contains(lowered, "getenforce") || strings.Contains(lowered, "semanage") || strings.Contains(lowered, "getsebool") || strings.Contains(lowered, "firewall-cmd"):
		return "the security policy or firewall state is correct"
	case strings.Contains(lowered, "systemctl") || strings.Contains(lowered, ".service") || strings.Contains(lowered, ".timer"):
		return "the service or timer state is correct"
	case strings.Contains(lowered, "chronyc") || strings.Contains(lowered, "chrony"):
		return "time synchronization is configured correctly"
	case strings.Contains(lowered, "podman") || strings.Contains(lowered, "container"):
		return "the container state is correct"
	case strings.Contains(lowered, "findmnt") || strings.Contains(lowered, "/etc/fstab") || strings.Contains(lowered, "blkid") || strings.Contains(lowered, "swapon") || strings.Contains(lowered, "lvs ") || strings.Contains(lowered, "vgs ") || strings.Contains(lowered, "xfs") || strings.Contains(lowered, "vfat"):
		return "the storage, filesystem, or mount state is correct"
	case strings.Contains(lowered, "useradd") || strings.Contains(lowered, "groupadd") || strings.Contains(lowered, "chage") || strings.Contains(lowered, "getent passwd") || strings.Contains(lowered, "getent group") || strings.Contains(lowered, "/etc/login.defs") || strings.Contains(lowered, "pwquality"):
		return "the user, group, or password policy state is correct"
	case strings.Contains(lowered, "crontab") || strings.Contains(lowered, " atq") || strings.Contains(lowered, "/var/spool/cron"):
		return "the scheduled job is configured correctly"
	case strings.Contains(lowered, "grubby") || strings.Contains(lowered, "grub2"):
		return "the boot loader configuration is correct"
	case strings.Contains(lowered, "rsyslog") || strings.Contains(lowered, "journald") || strings.Contains(lowered, "journal"):
		return "the logging configuration is correct"
	case strings.Contains(lowered, "tar ") || strings.Contains(lowered, ".tar") || strings.Contains(lowered, "gzip"):
		return "the archive exists with the required content"
	case strings.Contains(lowered, "test -f") || strings.Contains(lowered, "test -s") || strings.Contains(lowered, "grep") || strings.Contains(lowered, "diff") || strings.Contains(lowered, "stat"):
		return "the required file, content, or permission state is present"
	default:
		return "the required lab state is present"
	}
}

func normalizeTaskText(value string) string {
	value = strings.ReplaceAll(value, "\r\n", "\n")
	value = strings.Trim(value, "\n")
	rawLines := strings.Split(value, "\n")
	lines := make([]string, 0, len(rawLines))
	for _, line := range rawLines {
		lines = append(lines, strings.TrimRight(line, " \t"))
	}
	if len(lines) == 1 && lines[0] != "" {
		runes := []rune(lines[0])
		last := runes[len(runes)-1]
		if !strings.ContainsRune(".:!?", last) {
			lines[0] += "."
		}
	}
	return strings.TrimSpace(strings.Join(lines, "\n"))
}
