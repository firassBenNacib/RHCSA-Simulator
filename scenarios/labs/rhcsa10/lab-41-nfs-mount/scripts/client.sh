#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

dnf install -y nfs-utils >/dev/null 2>&1 || true
umount /mnt/serverdirect10 >/dev/null 2>&1 || true
sed -i '\#/mnt/serverdirect10#d' /etc/fstab
rm -rf /mnt/serverdirect10
