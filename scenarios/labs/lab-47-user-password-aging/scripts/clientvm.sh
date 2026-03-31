#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id aging47 >/dev/null 2>&1 || useradd -m aging47
printf 'aging47:redhat
' | chpasswd
chage -M 99999 -m 0 -W 7 aging47 >/dev/null 2>&1 || true
