#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
if command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args="audit_backlog_limit=8192" >/dev/null 2>&1 || true
fi
