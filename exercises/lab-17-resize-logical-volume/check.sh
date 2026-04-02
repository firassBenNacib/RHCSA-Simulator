#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-17-resize-logical-volume/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewlv" && $2=="reviewvg" && $3>=319 && $3<=321{found=1} END{exit !found}'

# Check 02 [clientvm]
findmnt -no TARGET,SOURCE /mnt/reviewlv | grep -Eq '^/mnt/reviewlv /dev/mapper/reviewvg-reviewlv$'
