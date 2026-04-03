#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
userdel -r cycle47 >/dev/null 2>&1 || true
useradd cycle47 >/dev/null 2>&1 || true
printf 'cycle47:cinder9\n' | chpasswd
chage -M 99999 -m 0 -W 7 cycle47 >/dev/null 2>&1 || true
chage -d -1 cycle47 >/dev/null 2>&1 || true
