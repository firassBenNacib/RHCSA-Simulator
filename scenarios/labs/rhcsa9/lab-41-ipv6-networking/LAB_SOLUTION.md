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
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - IPv6 Address Configuration (client) - 10 pts

```bash
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv6.method manual ipv6.addresses fd00:122:41::25/64 ipv6.gateway fd00:122:41::1 ipv6.dns fd00:122:41::53 connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
```

---

## Task 02 - Hostname And IPv6 Host Entry (client) - 10 pts

```bash
hostnamectl set-hostname client.ipv6lab.local
vim /etc/hosts
fd00:122:41::3 server.ipv6lab.local
```
