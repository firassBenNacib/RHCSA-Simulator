#!/usr/bin/env bash
set -euo pipefail

# Generated from scenarios/labs/lab-41-ipv6-networking/scenario.json
# Use ./RHCSA.ps1 check on the host to run these on the correct VM automatically.

# Check 01 [clientvm]
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"; test -n "$CONN"; test "$(nmcli -g ipv6.addresses connection show "$CONN")" = 'fd00:122:41::25/64' && test "$(nmcli -g ipv6.gateway connection show "$CONN")" = 'fd00:122:41::1' && test "$(nmcli -g ipv6.dns connection show "$CONN")" = 'fd00:122:41::53' && test "$(nmcli -g ipv6.method connection show "$CONN")" = 'manual'

# Check 02 [clientvm]
hostnamectl --static | grep -qx 'clientvm.ipv6lab.local'

# Check 03 [clientvm]
getent hosts servervm.ipv6lab.local | grep -Fq 'fd00:122:41::3'
