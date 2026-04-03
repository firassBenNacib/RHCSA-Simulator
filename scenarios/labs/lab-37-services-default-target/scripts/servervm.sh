#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
systemctl set-default graphical.target >/dev/null 2>&1 || true
systemctl disable --now rsyslog >/dev/null 2>&1 || true
systemctl enable --now postfix >/dev/null 2>&1 || true
