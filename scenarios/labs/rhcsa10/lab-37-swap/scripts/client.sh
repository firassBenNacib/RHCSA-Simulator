#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

swap_uuid="$(blkid -s UUID -o value /dev/sdb1 2>/dev/null || true)"
swapoff /dev/sdb1 2>/dev/null || true
if [ -n "$swap_uuid" ]; then
  sed -i "\#^UUID=$swap_uuid[[:space:]]#d;\#^/dev/disk/by-uuid/$swap_uuid[[:space:]]#d" /etc/fstab
fi
sed -i '\#^/dev/sdb1[[:space:]]#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
