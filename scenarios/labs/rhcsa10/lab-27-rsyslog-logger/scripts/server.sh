#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

rm -f /etc/rsyslog.d/rhcsa10.conf /var/log/rhcsa10-local7.log
systemctl disable --now rsyslog >/dev/null 2>&1 || true
