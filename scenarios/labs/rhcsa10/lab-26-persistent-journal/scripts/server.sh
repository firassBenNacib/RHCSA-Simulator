#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl restart systemd-journald >/dev/null 2>&1 || true
rm -rf /var/log/journal
rm -f /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf /etc/systemd/journald.conf.d/persistent.conf
sed -i '/^[[:space:]]*Storage[[:space:]]*=.*persistent/d' /etc/systemd/journald.conf 2>/dev/null || true
