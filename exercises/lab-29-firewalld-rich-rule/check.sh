#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-29-firewalld-rich-rule/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
firewall-cmd --list-rich-rules | grep -Fq 'source address="192.168.122.0/24"' && firewall-cmd --list-rich-rules | grep -Fq 'port port="2222" protocol="tcp" accept'
