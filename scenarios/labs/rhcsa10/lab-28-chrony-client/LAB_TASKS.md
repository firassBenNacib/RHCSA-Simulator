# RHCSA 10 Lab 28: Chrony Client

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-28-chrony-client` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, processes-logs-tuning |

Configure time synchronization.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure chrony time source (server) - 10 pts

On server, configure chronyd as a local time source for the 192.168.122.0/24 network.

---

## Task 02 - Configure chrony time source (client) - 10 pts

On client, install chrony if needed.

---

## Task 03 - Configure server as the only NTP source (client) - 10 pts

On client, configure server as the only NTP source.

---

## Task 04 - Configure chrony time source (client) - 10 pts

On client, enable and start chronyd.
