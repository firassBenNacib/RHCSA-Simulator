#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-19-login-messages/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
id orien19 >/dev/null && grep -Fqx 'echo "Welcome to you, user Orien, you are amazing!"' /home/orien19/.bash_profile

# Check 02 [clientvm]
grep -Fqx 'echo "Welcome ${USER}, you are logged in!"' /etc/profile.d/lab19-greeting.sh
