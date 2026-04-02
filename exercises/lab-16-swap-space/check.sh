#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-16-swap-space/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
swapon --noheadings --show=NAME | grep -qx '/dev/sdb1'

# Check 02 [clientvm]
blkid -o value -s TYPE /dev/sdb1 | grep -qx swap

# Check 03 [clientvm]
uuid="$(blkid -o value -s UUID /dev/sdb1)"; grep -Eq "^UUID=${uuid}[[:space:]]+swap[[:space:]]+swap[[:space:]]+" /etc/fstab
