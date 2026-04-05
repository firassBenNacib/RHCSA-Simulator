#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


umount /mnt/reviewlv >/dev/null 2>&1 || true
sed -i '\#/mnt/reviewlv#d' /etc/fstab
lvremove -fy /dev/reviewvg/reviewlv >/dev/null 2>&1 || true
vgremove -fy reviewvg >/dev/null 2>&1 || true
pvremove -ffy /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdc >/dev/null 2>&1 || true
printf 'label: gpt
,700M,L
' | sfdisk /dev/sdc >/dev/null 2>&1
partprobe /dev/sdc >/dev/null 2>&1 || true
pvcreate -ff -y /dev/sdc1 >/dev/null 2>&1
vgcreate reviewvg /dev/sdc1 >/dev/null 2>&1
lvcreate -n reviewlv -L 160M reviewvg >/dev/null 2>&1
mkfs.ext4 -F /dev/reviewvg/reviewlv >/dev/null 2>&1
mkdir -p /mnt/reviewlv
mount /dev/reviewvg/reviewlv /mnt/reviewlv
echo 'seed data' > /mnt/reviewlv/keep.txt
uuid="$(blkid -s UUID -o value /dev/reviewvg/reviewlv)"
printf 'UUID=%s /mnt/reviewlv ext4 defaults 0 0
' "$uuid" >> /etc/fstab
