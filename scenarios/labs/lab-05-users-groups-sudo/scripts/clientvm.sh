#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


for u in harryx natashax sarahx; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel sysadmx >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/sysadmx /etc/sudoers.d/harryx-passwd
