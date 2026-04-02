#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-35-process-priority-tuned/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
tuned-adm active | grep -q throughput-performance

# Check 02 [clientvm]
test -f /root/sleep35.pid

# Check 03 [clientvm]
ps -o ni= -p "$(cat /root/sleep35.pid)" | tr -d " " | grep -qx 5
