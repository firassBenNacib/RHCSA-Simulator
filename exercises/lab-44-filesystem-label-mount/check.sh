#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-44-filesystem-label-mount/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
blkid -o value -s LABEL /dev/sdb1 | grep -qx DATA44

# Check 02 [clientvm]
findmnt -no TARGET,SOURCE /data44 | grep -Eq '^/data44 /dev/sdb1$|^/data44 /dev/mapper/.+$' && grep -Eq '^[^#]*LABEL=DATA44[[:space:]]+/data44[[:space:]]+ext4' /etc/fstab
