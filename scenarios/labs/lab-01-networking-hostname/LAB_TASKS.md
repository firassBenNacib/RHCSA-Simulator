# Lab 01: Networking And Hostname

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-01-networking-hostname` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | networking-and-firewall |

Configure persistent networking and hostname settings on client in RHCSA style.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client Network Configuration (client) - 10 pts

Configure the active client connection with the following persistent settings:

- **IP Address:** 192.168.122.25
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** client.netlab.local

---

## Task 02 - Static Host Entry (client) - 10 pts

Add a persistent hosts entry with the following value:

- **Hostname:** repo.netlab.local
- **Address:** 192.168.122.3

---

## Task 03 - Reconnect Verification (client) - 10 pts

Verify that the active connection comes back with the same values after reconnecting it.
