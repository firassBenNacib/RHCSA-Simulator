# Lab 41: IPv6 Networking

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-41-ipv6-networking` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | networking-and-firewall |

Configure persistent IPv6 networking and hostname resolution on the client system.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - IPv6 Address Configuration (clientvm) - 10 pts

```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 == "eth1" {print $1; found = 1; exit} $2 != "" && $2 != "lo" && first == "" {first = $1} END {if (!found) print first}')"
test -n "$CONN"
nmcli connection modify "$CONN" ipv6.method manual ipv6.addresses fd00:122:41::25/64 ipv6.gateway fd00:122:41::1 ipv6.dns fd00:122:41::53 connection.autoconnect yes
```

---

## Task 02 - Hostname And IPv6 Host Entry (clientvm) - 10 pts

```bash
hostnamectl set-hostname clientvm.ipv6lab.local
vim /etc/hosts
fd00:122:41::3 servervm.ipv6lab.local
```

---

## Task 03 - Preserve Existing IPv4 Settings (clientvm) - 10 pts

```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 == "eth1" {print $1; found = 1; exit} $2 != "" && $2 != "lo" && first == "" {first = $1} END {if (!found) print first}')"
nmcli connection show "$CONN"
getent hosts servervm.ipv6lab.local
```
