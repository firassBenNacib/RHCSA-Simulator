#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-08-autofs-nfs/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
showmount -e servervm | grep -Eq '(^|[[:space:]])/exports/vault8([[:space:]]|$)'

# Check 02 [clientvm]
mount | grep -Eq 'servervm:/exports/vault8 on /netdir/vault8 type nfs'

# Check 03 [clientvm]
test -f /netdir/vault8/welcome.txt && grep -Fqx 'autofs lab 08' /netdir/vault8/welcome.txt
