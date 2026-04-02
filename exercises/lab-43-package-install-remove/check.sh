#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-43-package-install-remove/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
rpm -q tree

# Check 02 [clientvm]
! rpm -q dos2unix
