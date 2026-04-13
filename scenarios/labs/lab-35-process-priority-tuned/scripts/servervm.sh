#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
dnf install -y tuned >/dev/null 2>&1 || true
systemctl enable --now tuned >/dev/null 2>&1 || true
pkill -f '^sleep 3600$' >/dev/null 2>&1 || true
rm -f /root/sleep35.pid
tuned-adm profile balanced >/dev/null 2>&1 || true
