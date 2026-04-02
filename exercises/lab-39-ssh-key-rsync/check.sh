#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-39-ssh-key-rsync/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
ssh -o BatchMode=yes -o StrictHostKeyChecking=no mesh39@192.168.122.3 "test -f /home/mesh39/server-data/file1.txt"
