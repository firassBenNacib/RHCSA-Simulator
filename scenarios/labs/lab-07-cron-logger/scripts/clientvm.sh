#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


userdel -r ferro >/dev/null 2>&1 || true
crontab -r -u ferro >/dev/null 2>&1 || true
