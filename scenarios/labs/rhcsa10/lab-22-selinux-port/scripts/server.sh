#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

semanage port -d -t http_port_t -p tcp 8010 >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=8010/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
