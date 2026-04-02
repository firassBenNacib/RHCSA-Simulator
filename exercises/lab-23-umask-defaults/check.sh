#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-23-umask-defaults/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
id veil23

# Check 02 [clientvm]
runuser -l veil23 -c 'rm -rf ~/veil23-check && mkdir ~/veil23-check && touch ~/veil23-check/file && mkdir ~/veil23-check/dir && stat -c %a ~/veil23-check/file ~/veil23-check/dir'
