#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

if [ -s /run/rhcsa10-sleep.pid ]; then
    kill "$(cat /run/rhcsa10-sleep.pid)" >/dev/null 2>&1 || true
fi
rm -f /run/rhcsa10-sleep.pid
