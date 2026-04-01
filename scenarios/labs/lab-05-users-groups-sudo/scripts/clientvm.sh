#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


for u in brenor lyessa quillan; do userdel -r "$u" >/dev/null 2>&1 || true; done
groupdel opsrune >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/opsrune /etc/sudoers.d/brenor-passwd
