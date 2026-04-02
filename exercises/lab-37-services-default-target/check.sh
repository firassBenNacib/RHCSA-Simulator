#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-37-services-default-target/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
systemctl get-default | grep -qx multi-user.target

# Check 02 [clientvm]
systemctl is-enabled rsyslog | grep -qx enabled

# Check 03 [clientvm]
systemctl is-active rsyslog | grep -qx active
