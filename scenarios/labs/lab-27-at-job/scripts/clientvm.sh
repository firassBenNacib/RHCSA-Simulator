#!/usr/bin/env bash
set -euo pipefail
userdel -r atuser27 >/dev/null 2>&1 || true
while read -r job; do atrm "$job"; done < <(atq | awk '{print $1}')
systemctl disable --now atd >/dev/null 2>&1 || true
