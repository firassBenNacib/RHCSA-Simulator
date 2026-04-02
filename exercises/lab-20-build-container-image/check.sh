#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-20-build-container-image/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
runuser -l builder20 -c 'podman image exists localhost/text2pdf20:latest'
