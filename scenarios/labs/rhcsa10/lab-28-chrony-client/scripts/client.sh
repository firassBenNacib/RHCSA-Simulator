#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl disable --now chronyd >/dev/null 2>&1 || true
dnf remove -y chrony >/dev/null 2>&1 || true
rm -f /etc/chrony.conf
