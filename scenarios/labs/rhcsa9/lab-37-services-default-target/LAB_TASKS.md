# Lab 37: Services and Default Target

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-37-services-default-target` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, boot-and-recovery |

Manage the default target on client and key services on server.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set the default boot target on client (client) - 10 pts

On client, configure the system to boot into multi-user.target by default.

---

## Task 02 - Manage rsyslog and postfix on server (server) - 20 pts

On server, ensure the rsyslog service is enabled and running on server, and if postfix is installed disable it and stop it.
