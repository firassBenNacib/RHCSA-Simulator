#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

userdel -r at10 >/dev/null 2>&1 || true
systemctl disable --now atd >/dev/null 2>&1 || true
