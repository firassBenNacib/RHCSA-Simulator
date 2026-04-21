# Lab 50: Systemd Timer Unit

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-50-systemd-timer` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Create and enable a persistent systemd timer for RHCSA 10 practice.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the timer script (client) - 10 pts

Create /usr/local/sbin/rhcsa-timer10.sh so it appends the text TIMER10 OK to /var/log/rhcsa-timer10.log.

---

## Task 02 - Create the oneshot service (client) - 10 pts

Create a systemd oneshot service named rhcsa-timer10.service that runs /usr/local/sbin/rhcsa-timer10.sh.

---

## Task 03 - Create and enable the timer (client) - 10 pts

Create rhcsa-timer10.timer so it runs the service every 5 minutes, is persistent, and starts automatically at boot.
