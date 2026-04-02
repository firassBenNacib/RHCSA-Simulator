package backend

import (
	"errors"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

type Runner struct {
	root   string
	script string
	shell  string
	prefix []string
}

func New(root string) (*Runner, error) {
	shell, prefix, err := detectShell(filepath.Join(root, "RHCSA.ps1"))
	if err != nil {
		return nil, err
	}

	return &Runner{
		root:   root,
		script: filepath.Join(root, "RHCSA.ps1"),
		shell:  shell,
		prefix: prefix,
	}, nil
}

func (r *Runner) Command(args ...string) *exec.Cmd {
	commandArgs := append([]string{}, r.prefix...)
	commandArgs = append(commandArgs, args...)
	cmd := exec.Command(r.shell, commandArgs...)
	cmd.Dir = r.root
	return cmd
}

func (r *Runner) Run(args ...string) (string, error) {
	cmd := r.Command(args...)
	output, err := cmd.CombinedOutput()
	return strings.TrimSpace(string(output)), err
}

func detectShell(scriptPath string) (string, []string, error) {
	if runtime.GOOS == "windows" {
		path, err := exec.LookPath("powershell.exe")
		if err != nil {
			return "", nil, errors.New("powershell.exe not found")
		}
		return path, []string{"-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath}, nil
	}

	if path, err := exec.LookPath("powershell.exe"); err == nil {
		return path, []string{"-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath}, nil
	}

	if path, err := exec.LookPath("pwsh"); err == nil {
		return path, []string{"-NoProfile", "-File", scriptPath}, nil
	}

	return "", nil, errors.New("PowerShell not found")
}
