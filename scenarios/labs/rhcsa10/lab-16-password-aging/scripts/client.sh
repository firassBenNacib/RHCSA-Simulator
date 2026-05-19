#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

userdel -r aging10 >/dev/null 2>&1 || true
if grep -q '^PASS_WARN_AGE' /etc/login.defs; then
  sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs
else
  echo 'PASS_WARN_AGE 14' >> /etc/login.defs
fi
