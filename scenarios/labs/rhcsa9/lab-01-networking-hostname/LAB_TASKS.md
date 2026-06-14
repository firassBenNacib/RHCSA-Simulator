# Lab 01: Networking and Hostname

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-01-networking-hostname` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 35 minutes |
| Objectives | networking-and-firewall |

Configure persistent client networking and a matching server hostname for RHCSA practice.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client Network Configuration (client) - 10 pts

On client, configure the active client connection with the following persistent settings:

- **IP Address:** 192.168.122.25
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** client.netlab.local

---

## Task 02 - Server Hostname (server) - 10 pts

On server, set the persistent hostname to repo.netlab.local.

---

## Task 03 - Client Static Host Entry (client) - 10 pts

On client, add a persistent hosts entry with the following value:

- **Hostname:** repo.netlab.local
- **Address:** 192.168.122.3
