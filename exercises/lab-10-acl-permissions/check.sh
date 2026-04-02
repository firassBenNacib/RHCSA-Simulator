#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-10-acl-permissions/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
stat -c '%U:%G %a' /var/tmp/fstab-acl | grep -qx 'root:root 644'

# Check 02 [clientvm]
getfacl -cp /var/tmp/fstab-acl | grep -qx 'user:natacl:rw-' && getfacl -cp /var/tmp/fstab-acl | grep -qx 'user:haracl:---' && getfacl -cp /var/tmp/fstab-acl | grep -qx 'other::r--'
