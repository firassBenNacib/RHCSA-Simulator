# RHCSA 10 Lab 02: IPv4 Networking

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-02-ipv4-nmcli` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | networking-and-firewall |

Configure persistent IPv4 networking with NetworkManager.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure the active client connection with IPv4 address 192.168.122.45/ (client) - 10 pts

```bash
nmcli connection modify 'System eth1' ipv4.addresses 192.168.122.45/24
```

---

## Task 02 - Set gateway 192.168.122.1 and DNS server 192.168.122.3 (client) - 10 pts

```bash
nmcli connection modify 'System eth1' ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3
```

---

## Task 03 - Ensure the connection uses manual IPv4 configuration and autoconnects (client) - 10 pts

```bash
nmcli connection modify 'System eth1' ipv4.method manual connection.autoconnect yes
nmcli connection up 'System eth1'
```
