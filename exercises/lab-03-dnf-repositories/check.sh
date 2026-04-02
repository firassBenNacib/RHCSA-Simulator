#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-03-dnf-repositories/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
dnf repolist | grep -Eq 'rhcsa-baseos|BaseOS' && dnf repolist | grep -Eq 'rhcsa-appstream|AppStream'

# Check 02 [servervm]
# Source: ssh admin@servervm sudo dnf repolist | grep -Eq 'rhcsa-baseos|BaseOS' && ssh admin@servervm sudo dnf repolist | grep -Eq 'rhcsa-appstream|AppStream'
dnf repolist | grep -Eq 'rhcsa-baseos|BaseOS' && ssh admin@servervm sudo dnf repolist | grep -Eq 'rhcsa-appstream|AppStream'
