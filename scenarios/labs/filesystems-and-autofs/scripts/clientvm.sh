#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

umount /mnt/direct-share >/dev/null 2>&1 || true
automount -u >/dev/null 2>&1 || true
rm -rf /projects /mnt/direct-share
mkdir -p /projects /mnt/direct-share

rhcsa_remove_matching_lines '/mnt/direct-share' /etc/fstab
rm -f /etc/auto.master.d/rhcsa.autofs /etc/auto.rhcsa
systemctl disable --now autofs >/dev/null 2>&1 || true
