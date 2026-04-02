#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-36-nfs-direct-mount/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
grep -Eq '^[^#].*192\.168\.122\.3:/exports/direct36[[:space:]]+/mnt/direct36[[:space:]]+nfs[[:space:]]+ro,sync' /etc/fstab

# Check 02 [clientvm]
mountpoint -q /mnt/direct36

# Check 03 [clientvm]
test -f /mnt/direct36/nfs36.txt
