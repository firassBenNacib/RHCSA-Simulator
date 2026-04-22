#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


automount -u >/dev/null 2>&1 || true
rm -rf /netdir
rm -f /etc/auto.lab8 /etc/auto.master.d/lab8.autofs
systemctl disable --now autofs >/dev/null 2>&1 || true
userdel -r vault8 >/dev/null 2>&1 || true
