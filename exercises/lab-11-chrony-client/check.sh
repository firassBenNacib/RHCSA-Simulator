#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-11-chrony-client/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
awk '$1 ~ /^(server|pool)$/ { if ($2 != "servervm") bad=1; if ($1=="server" && $2=="servervm") good=1 } END { exit !(good && !bad) }' /etc/chrony.conf

# Check 02 [clientvm]
systemctl is-enabled chronyd | grep -qx enabled && systemctl is-active chronyd | grep -qx active
