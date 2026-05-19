#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

umount /mnt/grow10 >/dev/null 2>&1 || true
sed -i '\#/mnt/grow10#d' /etc/fstab
lvremove -fy /dev/grow10/growlv >/dev/null 2>&1 || true
vgremove -fy grow10 >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
