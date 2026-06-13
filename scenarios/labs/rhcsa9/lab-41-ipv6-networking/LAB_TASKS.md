# Lab 41: IPv6 Networking

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-41-ipv6-networking` |
| Mode | Lab |
| Scope | client |
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

On client, configure the active client connection with the following persistent IPv6 settings:

- **IPv6 Address:** fd00:122:41::25/64
- **IPv6 Gateway:** fd00:122:41::1
- **Dns:** fd00:122:41::53

---

## Task 02 - Hostname and IPv6 Host Entry (client) - 10 pts

On client, set the following persistent identity and resolution settings on client:

- **Hostname:** client.ipv6lab.local
- **Static host entry:** server.ipv6lab.local
- **Address:** fd00:122:41::3
