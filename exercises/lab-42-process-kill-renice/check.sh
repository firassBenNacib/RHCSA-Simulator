#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-42-process-kill-renice/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
[ ! -d "/proc/$(cat /home/worker42/cpu.pid)" ]

# Check 02 [clientvm]
ps -o ni= -p "$(cat /home/worker42/sleep.pid)" | tr -d ' ' | grep -qx 10
