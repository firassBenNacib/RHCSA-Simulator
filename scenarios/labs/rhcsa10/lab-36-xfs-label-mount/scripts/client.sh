#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

umount /mnt/rhcsa10data >/dev/null 2>&1 || true
sed -i '\#/mnt/rhcsa10data#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
