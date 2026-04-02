# Lab 41: IPv6 Networking Solution

## Task 01 - IPv6 Address Configuration (clientvm) - 10 pts

```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv6.method manual ipv6.addresses fd00:122:41::25/64 ipv6.gateway fd00:122:41::1 ipv6.dns fd00:122:41::53 connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
```

## Task 02 - Hostname And IPv6 Host Entry (clientvm) - 10 pts

```bash
hostnamectl set-hostname clientvm.ipv6lab.local
vim /etc/hosts
fd00:122:41::3 servervm.ipv6lab.local
:wq
```

## Task 03 - Preserve Existing IPv4 Settings (clientvm) - 10 pts

```bash
nmcli connection show "$CONN" | grep -E "ipv6.addresses|ipv6.gateway|ipv6.dns"
getent hosts servervm.ipv6lab.local
```

## Verification

```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"; test -n "$CONN"; test "$(nmcli -g ipv6.addresses connection show "$CONN")" = 'fd00:122:41::25/64' && test "$(nmcli -g ipv6.gateway connection show "$CONN")" = 'fd00:122:41::1' && test "$(nmcli -g ipv6.dns connection show "$CONN")" = 'fd00:122:41::53' && test "$(nmcli -g ipv6.method connection show "$CONN")" = 'manual'
hostnamectl --static | grep -qx 'clientvm.ipv6lab.local'
getent hosts servervm.ipv6lab.local | grep -Fq 'fd00:122:41::3'
```
