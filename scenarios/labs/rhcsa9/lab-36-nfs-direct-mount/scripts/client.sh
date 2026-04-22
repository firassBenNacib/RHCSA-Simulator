#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
umount /mnt/direct36 >/dev/null 2>&1 || true
sed -i '\#/mnt/direct36#d' /etc/fstab
mkdir -p /mnt/direct36
