#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id cycle47 >/dev/null 2>&1 || useradd -m cycle47
printf 'cycle47:cinder9
' | chpasswd
chage -M 99999 -m 0 -W 7 cycle47 >/dev/null 2>&1 || true
