# Lab 34: Journald Persistence and Rsyslog

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-34-journald-rsyslog` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning, software-scheduling-time |

Configure persistent journal storage and a custom rsyslog drop-in for authentication warnings.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client journald persistence (client) - 10 pts

On client, configure journald so logs are stored persistently across reboots.

---

## Task 02 - Server rsyslog authpriv rule (server) - 10 pts

On server, create the drop-in file /etc/rsyslog.d/10-auth34.conf so authpriv messages with priority warning and higher are written to /var/log/auth34.log.

---

## Task 03 - Server rsyslog service (server) - 10 pts

On server, ensure the rsyslog service is active after your changes.
