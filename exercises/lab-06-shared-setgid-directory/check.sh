#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-06-shared-setgid-directory/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
stat -c '%A %a %G' /shared/analysts | grep -qx 'drwxrws--- 2770 analystsx'
