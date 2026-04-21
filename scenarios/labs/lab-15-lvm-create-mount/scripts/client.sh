#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


for target in /mnt/wsharex; do umount "$target" >/dev/null 2>&1 || true; done
sed -i '\#/mnt/wsharex#d' /etc/fstab
lvremove -fy /dev/wgroupx/wsharex >/dev/null 2>&1 || true
vgremove -fy wgroupx >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
