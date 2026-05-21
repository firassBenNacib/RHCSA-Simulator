#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl disable --now rhcsa10-timer.timer >/dev/null 2>&1 || true
rm -f /etc/systemd/system/rhcsa10-timer.service /etc/systemd/system/rhcsa10-timer.timer /usr/local/sbin/rhcsa10-timer.sh /var/log/rhcsa10-timer.log
systemctl daemon-reload
