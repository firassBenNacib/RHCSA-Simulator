#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-21-run-container/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
runuser -l runner21 -c 'podman ps --format {{.Names}}' | grep -qx mycontainer21
