#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-12-find-copy-preserve/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
diff -u <(find /opt/lab12/source -type f -user natfind -mtime -1 | sed 's#^/opt/lab12/source#/root/natfind-files#' | sort) <(find /root/natfind-files -type f | sort)
