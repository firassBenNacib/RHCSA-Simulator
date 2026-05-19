#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
umount /data44 >/dev/null 2>&1 || true
sed -i '\#/data44#d' /etc/fstab
wipefs -a /dev/sdb1 >/dev/null 2>&1 || true
wipefs -a /dev/sdb >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdb bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
partprobe /dev/sdb >/dev/null 2>&1 || true
rm -rf /data44
