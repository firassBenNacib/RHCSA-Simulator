#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-38-selinux-boolean/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
getsebool httpd_can_network_connect | grep -q "--> on"

# Check 02 [clientvm]
getenforce | grep -qx Enforcing
