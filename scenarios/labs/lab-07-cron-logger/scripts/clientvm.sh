#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


userdel -r natcron >/dev/null 2>&1 || true
crontab -r -u natcron >/dev/null 2>&1 || true
