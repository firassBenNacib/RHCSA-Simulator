package main

import (
	"fmt"
	"os/exec"
	"strings"
)

type clipboardCommand struct {
	name string
	args []string
}

func clipboardCommandCandidates() []clipboardCommand {
	return []clipboardCommand{
		{name: "cmd.exe", args: []string{"/c", "clip"}},
		{name: "clip.exe"},
		{name: "pbcopy"},
		{name: "wl-copy"},
		{name: "xclip", args: []string{"-selection", "clipboard"}},
		{name: "xsel", args: []string{"--clipboard", "--input"}},
	}
}

var clipboardCopy = copyTextToClipboard

func copyTextToClipboard(text string) error {
	text = strings.TrimSpace(text)
	if text == "" {
		return fmt.Errorf("nothing to copy")
	}

	var attempted []string
	for _, candidate := range clipboardCommandCandidates() {
		if _, err := exec.LookPath(candidate.name); err != nil {
			continue
		}

		cmd := exec.Command(candidate.name, candidate.args...)
		cmd.Stdin = strings.NewReader(text)
		if output, err := cmd.CombinedOutput(); err == nil {
			return nil
		} else {
			attempted = append(attempted, fmt.Sprintf("%s: %v %s", candidate.name, err, strings.TrimSpace(string(output))))
		}
	}

	if len(attempted) == 0 {
		return fmt.Errorf("no clipboard command found")
	}
	return fmt.Errorf("clipboard copy failed")
}
