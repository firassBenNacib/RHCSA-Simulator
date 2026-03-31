#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
setsebool -P httpd_can_network_connect off >/dev/null 2>&1 || true
setenforce 1 >/dev/null 2>&1 || true
