# RHCSA 10 Lab 31: Systemd Timer

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-31-systemd-timer` |
| Mode | Lab |
| Scope | server |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Create and enable a persistent systemd timer.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /usr/local/sbin/rhcsa10-timer.sh so it appends TIMER OK to (server) - 10 pts

On server, create /usr/local/sbin/rhcsa10-timer.sh so it appends TIMER OK to /var/log/rhcsa10-timer.log.

---

## Task 02 - Create a oneshot service named rhcsa10-timer.service that runs (server) - 10 pts

On server, create a oneshot service named rhcsa10-timer.service that runs /usr/local/sbin/rhcsa10-timer.sh.

---

## Task 03 - Create rhcsa10-timer.timer so it runs every 5 minutes, is persistent (server) - 10 pts

On server, create rhcsa10-timer.timer so it runs every 5 minutes, is persistent, and starts automatically at boot.
