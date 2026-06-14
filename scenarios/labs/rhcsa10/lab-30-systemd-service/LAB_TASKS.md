# RHCSA 10 Lab 30: Custom Service

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-30-systemd-service` |
| Mode | Lab |
| Scope | server |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Create and enable a custom systemd service.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /usr/local/sbin/rhcsa10-service.sh that writes SERVICE10 to (server) - 10 pts

On server, create /usr/local/sbin/rhcsa10-service.sh that writes SERVICE10 to /var/tmp/rhcsa10-service.out.

---

## Task 02 - Create a oneshot service named rhcsa10-service.service that runs the (server) - 10 pts

On server, create a oneshot service named rhcsa10-service.service that runs the script.

---

## Task 03 - Enable and start the service (server) - 10 pts

On server, enable and start the service.
