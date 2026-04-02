#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-18-tuned-profile/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
rec="$(tuned-adm recommended | awk '{print $1}')"; act="$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\1/')"; test -n "$rec" && test "$act" = "$rec"
