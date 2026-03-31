#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

umount /srv/labdata >/dev/null 2>&1 || true
umount /mnt/labext4 >/dev/null 2>&1 || true
swapoff /dev/mapper/rhcsa_vg-labswap >/dev/null 2>&1 || true

sed -i '\#/srv/labdata#d' /etc/fstab
sed -i '\#/mnt/labext4#d' /etc/fstab
sed -i '\#labswap#d' /etc/fstab

lvremove -fy /dev/rhcsa_vg/labdata >/dev/null 2>&1 || true
lvremove -fy /dev/rhcsa_vg/labswap >/dev/null 2>&1 || true
lvremove -fy /dev/rhcsa_vg/labext4 >/dev/null 2>&1 || true
vgremove -fy rhcsa_vg >/dev/null 2>&1 || true
pvremove -ffy /dev/sdb /dev/sdc >/dev/null 2>&1 || true

mkdir -p /srv/labdata /mnt/labext4
