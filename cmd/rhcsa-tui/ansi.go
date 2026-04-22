package main

import "regexp"

var ansiRegex = regexp.MustCompile(`\x1b\[[0-9;]*[a-zA-Z]`)

func StripAnsi(s string) string {
	return ansiRegex.ReplaceAllString(s, "")
}
