#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

groupdel share10 >/dev/null 2>&1 || true
rm -rf /srv/share10
