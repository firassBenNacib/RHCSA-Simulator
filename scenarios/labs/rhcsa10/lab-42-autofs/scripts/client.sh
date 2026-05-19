#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

systemctl disable --now autofs >/dev/null 2>&1 || true
rm -f /etc/auto.remote10 /etc/auto.master.d/rhcsa10.autofs
automount -u >/dev/null 2>&1 || true
rm -rf /remote10
