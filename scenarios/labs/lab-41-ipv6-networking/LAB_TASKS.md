# Lab 41: IPv6 Networking

## Lab Tasks
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

Configure the active clientvm connection with the following persistent IPv6 settings:

- **IPv6 Address:** fd00:122:41::25/64
- **IPv6 Gateway:** fd00:122:41::1
- **DNS Server:** fd00:122:41::53

---

## Task 02 - Hostname And IPv6 Host Entry (clientvm) - 10 pts

Set the following persistent identity and resolution settings on clientvm:

- **Hostname:** clientvm.ipv6lab.local
- **Static host entry:** servervm.ipv6lab.local
- **Address:** fd00:122:41::3

---

## Task 03 - Preserve Existing IPv4 Settings (clientvm) - 10 pts

Leave the existing IPv4 configuration unchanged.
