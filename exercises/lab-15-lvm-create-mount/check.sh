#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-15-lvm-create-mount/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
pvs --noheadings -o pv_name,vg_name | awk '$1=="/dev/sdb1" && $2=="wgroupx"{found=1} END{exit !found}'

# Check 02 [clientvm]
vgs --noheadings -o vg_name,vg_extent_size --units m --nosuffix | awk '$1=="wgroupx" && int($2)==8{found=1} END{exit !found}'

# Check 03 [clientvm]
lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="wsharex" && $2=="wgroupx" && $3>=399 && $3<=401{found=1} END{exit !found}'

# Check 04 [clientvm]
blkid -o value -s TYPE /dev/wgroupx/wsharex | grep -qx ext4

# Check 05 [clientvm]
findmnt -no TARGET,SOURCE,FSTYPE /mnt/wsharex | grep -Eq '^/mnt/wsharex /dev/mapper/wgroupx-wsharex ext4$'
