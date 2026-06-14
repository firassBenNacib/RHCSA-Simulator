#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


tuned-adm profile balanced >/dev/null 2>&1 || true
