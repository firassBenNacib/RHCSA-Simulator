#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-22-container-autostart/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
loginctl show-user merin22 | grep -Eq '^Linger=yes$'

# Check 02 [clientvm]
runuser -l merin22 -c 'systemctl --user is-enabled container-render22.service' | grep -qx enabled

# Check 03 [clientvm]
runuser -l merin22 -c 'systemctl --user is-active container-render22.service' | grep -qx active
