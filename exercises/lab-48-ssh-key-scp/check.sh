#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-48-ssh-key-scp/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bridge48@192.168.122.3 "test -f /home/bridge48/inbox/payload.txt"
