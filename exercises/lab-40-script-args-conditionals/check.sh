#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-40-script-args-conditionals/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
id script40 >/dev/null 2>&1

# Check 02 [clientvm]
/usr/local/bin/usercheck40 script40 | grep -qx 'EXISTS: script40'

# Check 03 [clientvm]
output="$(/usr/local/bin/usercheck40 nosuch40 2>/dev/null || true)"; test "$output" = 'MISSING: nosuch40'
