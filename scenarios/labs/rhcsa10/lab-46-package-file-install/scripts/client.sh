#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

dnf remove -y tree >/dev/null 2>&1 || true
