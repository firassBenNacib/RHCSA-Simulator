#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-46-container-inspect/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
runuser -l scope46 -c "test -s ~/workdir.txt && test -s ~/user.txt"
