#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-26-default-acl-shared-dir/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
stat -c '%U:%G %a' /shared/collab26 | grep -qx 'root:collab26 2770' && getfacl -cp /shared/collab26 | grep -qx 'default:user:probe26:rwx'
