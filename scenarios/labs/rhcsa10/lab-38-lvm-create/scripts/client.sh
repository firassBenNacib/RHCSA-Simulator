#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

umount /mnt/lvdata10 >/dev/null 2>&1 || true
sed -i '\#/mnt/lvdata10#d' /etc/fstab
lvremove -fy /dev/vg10/lvdata >/dev/null 2>&1 || true
vgremove -fy vg10 >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
