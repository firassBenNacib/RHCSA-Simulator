package main

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

func (m model) statusBody() string {
	if strings.TrimSpace(m.statusText) == "" {
		return ""
	}

	width := max(m.width-detailPaneBorder, minDetailTextWidth)
	lines := strings.Split(m.statusText, "\n")
	rendered := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			rendered = append(rendered, "")
			continue
		}
		rendered = appendWrappedLines(rendered, line, width, m.statusLineStyle(line))
	}
	return strings.Join(rendered, "\n")
}

func (m model) statusLineStyle(line string) lipgloss.Style {
	switch m.statusLineTone(line) {
	case "error":
		return m.theme.OutputError
	case "success":
		return m.theme.OutputSuccess
	case "warning":
		return m.theme.OutputWarning
	case "muted":
		return m.theme.OutputMuted
	case "info":
		return m.theme.OutputInfo
	default:
		return lipgloss.NewStyle()
	}
}

func (m model) statusLineTone(line string) string {
	trimmed := strings.TrimSpace(line)
	lowered := strings.ToLower(trimmed)

	switch {
	case strings.HasPrefix(trimmed, "Error:"),
		strings.HasPrefix(trimmed, "[fail]"),
		strings.HasPrefix(trimmed, "Fail "):
		return "error"
	case strings.HasPrefix(trimmed, "[ok]"),
		strings.HasPrefix(trimmed, "Started "),
		strings.HasPrefix(trimmed, "Reset complete"),
		strings.HasPrefix(trimmed, "Baseline ready"),
		strings.HasPrefix(trimmed, "SSH session opened"),
		strings.HasPrefix(trimmed, "Repo: available"),
		strings.HasPrefix(trimmed, "Result: complete"):
		return "success"
	case strings.HasPrefix(trimmed, "Warning:"),
		strings.HasPrefix(trimmed, "Result: incomplete"),
		strings.HasPrefix(trimmed, "Repo: unavailable"),
		strings.Contains(lowered, "virtualbox is busy"),
		strings.Contains(lowered, "timed out"),
		strings.Contains(lowered, "stale virtualbox disk"),
		strings.Contains(lowered, "child disk attached"):
		return "warning"
	case strings.HasPrefix(trimmed, "Use:"),
		strings.HasPrefix(trimmed, "A new PowerShell window was opened"):
		return "muted"
	case strings.HasPrefix(trimmed, "Lab:"),
		strings.HasPrefix(trimmed, "Already active"),
		strings.HasPrefix(trimmed, "Progress check"),
		strings.HasPrefix(trimmed, "Simulator destroyed"),
		strings.HasPrefix(trimmed, "Lab destroyed"),
		strings.HasPrefix(trimmed, "Result:"),
		strings.HasPrefix(trimmed, "Repo:"):
		return "info"
	default:
		return "default"
	}
}

func summarizeActionOutput(output string) string {
	clean := StripAnsi(output)
	switch {
	case strings.Contains(clean, "LockMachine") || strings.Contains(clean, "lock request pending"):
		return "VirtualBox is busy\nWait a few seconds, then try the action again"
	case strings.Contains(clean, "timeout during server version negotiating"):
		return "SSH handshake timed out\nTry the action again once the VM finishes booting"
	case strings.Contains(clean, "VERR_ALREADY_EXISTS"):
		return "A stale VirtualBox disk is still registered\nRun destroy, then up, and try again"
	case strings.Contains(clean, "Cannot close medium"):
		return "VirtualBox still has a child disk attached\nRun destroy again after a few seconds"
	}

	lines := strings.Split(strings.TrimSpace(clean), "\n")
	filtered := make([]string, 0, len(lines))
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || trimmed == "Command returned a non-zero exit status." {
			continue
		}
		if matches := failLinePattern.FindStringSubmatch(trimmed); len(matches) >= 2 {
			label := summarizeCheckLabel(matches[1])
			filtered = append(filtered, fmt.Sprintf("[fail] %s", label))
			continue
		}
		if matches := failDetailPattern.FindStringSubmatch(trimmed); len(matches) >= 4 {
			label := summarizeCheckLabel(matches[3])
			filtered = append(filtered, fmt.Sprintf("Fail %s: [%s] %s", matches[1], matches[2], label))
			continue
		}
		if isSignificantLine(trimmed) {
			filtered = append(filtered, trimmed)
		}
	}

	if len(filtered) == 0 {
		if len(lines) > 0 {
			filtered = append(filtered, truncateLine(strings.TrimSpace(lines[0]), 140))
		}
		if len(lines) > 1 {
			filtered = append(filtered, truncateLine(strings.TrimSpace(lines[len(lines)-1]), 140))
		}
	}
	if len(filtered) > defaultMaxStatusLines {
		filtered = filtered[len(filtered)-defaultMaxStatusLines:]
	}
	return strings.Join(filtered, "\n")
}

func isSignificantLine(trimmed string) bool {
	significantPrefixes := []string{
		"Error:", "Use:", "Started ", "Already active", "Reset complete", "Progress check",
		"SSH session opened", "Lab destroyed", "Simulator destroyed",
		"Baseline ready", "Result:", "Lab:", "A new PowerShell window was opened",
		"[fail]", "[ok]", "Fail ",
	}
	significantContains := []string{
		"VirtualBox is already locked", "already has a lock request pending",
		"LockMachine", "timeout during server version negotiating",
		"Cannot close medium", "VERR_ALREADY_EXISTS",
	}
	for _, p := range significantPrefixes {
		if strings.HasPrefix(trimmed, p) {
			return true
		}
	}
	for _, c := range significantContains {
		if strings.Contains(trimmed, c) {
			return true
		}
	}
	return false
}

func summarizeCheckLabel(command string) string {
	lowered := strings.ToLower(command)
	switch {
	case strings.Contains(lowered, "repomd.xml") || strings.Contains(lowered, "/etc/yum.repos.d") || strings.Contains(lowered, "dnf -q repolist") || strings.Contains(lowered, "baseos") || strings.Contains(lowered, "appstream"):
		return "repository check failed"
	case strings.Contains(lowered, "ls -zd /root") || strings.Contains(lowered, "admin_home_t") || strings.Contains(lowered, "restorecon") || strings.Contains(lowered, "autorelabel"):
		return "selinux relabel check failed"
	case strings.Contains(lowered, "passwordauthentication") || strings.Contains(lowered, "permitrootlogin") || strings.Contains(lowered, "/etc/ssh/sshd_config") || strings.Contains(lowered, "sshd -t"):
		return "ssh access check failed"
	case strings.Contains(lowered, "hostnamectl") || strings.Contains(lowered, "--static"):
		return "hostname check failed"
	case strings.Contains(lowered, "/etc/hosts") || strings.Contains(lowered, "getent hosts"):
		return "hosts entry check failed"
	case strings.Contains(lowered, "nmcli") || strings.Contains(lowered, "ipv4.addresses") || strings.Contains(lowered, "ipv4.gateway") || strings.Contains(lowered, "ipv4.dns") || strings.Contains(lowered, "ipv4.method") || strings.Contains(lowered, "connection.autoconnect"):
		return "network profile check failed"
	case strings.Contains(lowered, "systemctl"):
		return "service check failed"
	case strings.Contains(lowered, "firewall-cmd") || strings.Contains(lowered, "semanage") || strings.Contains(lowered, "getenforce"):
		return "security check failed"
	case strings.Contains(lowered, "podman") || strings.Contains(lowered, "container"):
		return "container check failed"
	case strings.Contains(lowered, "mount") || strings.Contains(lowered, "findmnt") || strings.Contains(lowered, "/etc/fstab") || strings.Contains(lowered, "swapon"):
		return "storage check failed"
	case strings.Contains(lowered, "useradd") || strings.Contains(lowered, "groupadd") || strings.Contains(lowered, "chage") || strings.Contains(lowered, "getent passwd"):
		return "user check failed"
	default:
		return "check failed"
	}
}
