#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-09-archive-bzip2/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
tar -tjf /root/myetcbackup.tar.bz2 | grep -Eq '^etc/$|^etc/'
