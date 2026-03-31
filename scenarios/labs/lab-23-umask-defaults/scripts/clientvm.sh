#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
userdel -r umask23 >/dev/null 2>&1 || true
