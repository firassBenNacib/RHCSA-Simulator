#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id script40 >/dev/null 2>&1 || useradd -m script40
rm -f /usr/local/bin/usercheck40
