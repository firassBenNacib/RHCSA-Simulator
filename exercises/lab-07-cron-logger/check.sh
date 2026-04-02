#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-07-cron-logger/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
crontab -l -u ferro | grep -Fqx '*/2 * * * * logger "Lab 07 running"'

# Check 02 [clientvm]
systemctl is-enabled crond | grep -qx enabled && systemctl is-active crond | grep -qx active
