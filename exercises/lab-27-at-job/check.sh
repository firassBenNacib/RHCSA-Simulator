#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-27-at-job/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
systemctl is-enabled atd | grep -qx enabled

# Check 02 [clientvm]
systemctl is-active atd | grep -qx active

# Check 03 [clientvm]
atq | grep -q queue27
