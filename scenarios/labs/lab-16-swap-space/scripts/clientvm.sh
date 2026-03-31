#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


swapoff /dev/sdb1 >/dev/null 2>&1 || true
sed -i '\# /swap #d' /etc/fstab
sed -i '\#/dev/sdb1#d' /etc/fstab
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
