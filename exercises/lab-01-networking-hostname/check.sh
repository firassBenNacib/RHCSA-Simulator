#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-01-networking-hostname/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
hostnamectl --static | grep -qx 'clientvm.netlab.local'

# Check 02 [clientvm]
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"; test -n "$CONN"; test "$(nmcli -g ipv4.addresses connection show "$CONN")" = '192.168.122.25/24' && test "$(nmcli -g ipv4.gateway connection show "$CONN")" = '192.168.122.1' && test "$(nmcli -g ipv4.dns connection show "$CONN")" = '192.168.122.3' && test "$(nmcli -g ipv4.method connection show "$CONN")" = 'manual'

# Check 03 [clientvm]
grep -Eq '^192\.168\.122\.3[[:space:]]+repo\.netlab\.local([[:space:]]|$)' /etc/hosts
