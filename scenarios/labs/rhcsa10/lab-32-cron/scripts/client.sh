#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

userdel -r cron10 >/dev/null 2>&1 || true
systemctl disable --now crond >/dev/null 2>&1 || true
