# Lab 34: Journald Persistence and Rsyslog

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-34-journald-rsyslog` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning, software-scheduling-time |

Configure persistent journal storage and a custom rsyslog drop-in for authentication warnings.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure journald on client so logs are stored (client) - 10 pts

Configure journald on client so logs are stored persistently across reboots using a valid [Journal] Storage=persistent configuration.

---

## Task 02 - Create the drop-in file (client) - 10 pts

Create the drop-in file /etc/rsyslog.d/10-auth34.conf so authpriv messages with priority warning and higher are written to /var/log/auth34.log.

---

## Task 03 - Ensure the rsyslog service is active after your (client) - 10 pts

Ensure the rsyslog service is active after your changes.
