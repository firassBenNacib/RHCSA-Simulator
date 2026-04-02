#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-32-ssh-key-auth/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
runuser -l relay32 -c 'ssh -o StrictHostKeyChecking=no -o BatchMode=yes vault32@servervm true'
