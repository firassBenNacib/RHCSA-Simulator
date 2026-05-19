#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

rm -rf /var/log/journal
sed -i 's/^Storage=persistent/Storage=auto/' /etc/systemd/journald.conf >/dev/null 2>&1 || true
systemctl restart systemd-journald >/dev/null 2>&1 || true
