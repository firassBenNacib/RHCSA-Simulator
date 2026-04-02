#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-14-user-fixed-uid/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
id -u tavric | grep -qx '4111'
