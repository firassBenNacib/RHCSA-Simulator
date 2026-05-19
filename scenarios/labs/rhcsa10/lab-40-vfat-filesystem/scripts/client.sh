#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

umount /mnt/vfat10 >/dev/null 2>&1 || true
sed -i '\#/mnt/vfat10#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
