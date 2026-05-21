#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl disable --now rhcsa10-service.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/rhcsa10-service.service /usr/local/sbin/rhcsa10-service.sh /var/tmp/rhcsa10-service.out
systemctl daemon-reload
