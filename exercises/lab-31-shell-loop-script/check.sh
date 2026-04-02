#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-31-shell-loop-script/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
diff -u <(find /opt/lab31 -maxdepth 1 -type f -name '*.log' | sort) <(sort /root/listlogs31.out)
