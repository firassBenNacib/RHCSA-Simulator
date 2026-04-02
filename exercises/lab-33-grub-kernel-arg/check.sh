#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-33-grub-kernel-arg/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
grubby --info=ALL | grep -E "^args=" | grep -q "audit_backlog_limit=8192"
