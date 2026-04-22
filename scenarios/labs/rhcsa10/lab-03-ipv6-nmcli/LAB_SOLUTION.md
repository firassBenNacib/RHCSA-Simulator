# RHCSA 10 Lab 03: IPv6 Networking

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-03-ipv6-nmcli` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | networking-and-firewall |

Configure persistent IPv6 networking with NetworkManager.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure the active client connection with IPv6 address fd00:10::45/64 (client) - 10 pts

```bash
nmcli connection modify 'System eth1' ipv6.addresses fd00:10::45/64
```

---

## Task 02 - Set IPv6 gateway fd00:10::1 (client) - 10 pts

```bash
nmcli connection modify 'System eth1' ipv6.gateway fd00:10::1
```

---

## Task 03 - Ensure IPv6 method is manual and the profile autoconnects (client) - 10 pts

```bash
nmcli connection modify 'System eth1' ipv6.method manual connection.autoconnect yes
nmcli connection up 'System eth1'
```
