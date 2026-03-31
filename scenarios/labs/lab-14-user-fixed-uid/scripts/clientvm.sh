#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


userdel -r choubix >/dev/null 2>&1 || true
