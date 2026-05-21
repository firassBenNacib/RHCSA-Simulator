#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl restart systemd-journald >/dev/null 2>&1 || true
rm -rf /var/log/journal
sed -i '/^Storage=/d' /etc/systemd/journald.conf 2>/dev/null || true
