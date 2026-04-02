#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-13-grep-filter/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
test -s /root/lines && grep -q 'ich' /root/lines && ! awk 'index($0,"ich")==0{print; exit 1}' /root/lines
