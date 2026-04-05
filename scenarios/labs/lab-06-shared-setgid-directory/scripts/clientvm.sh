#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
groupdel analystsx 2>/dev/null || true
rm -rf /shared/analysts
mkdir -p /shared
