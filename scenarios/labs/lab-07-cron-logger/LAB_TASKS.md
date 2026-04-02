# Lab 07: Cron Scheduling

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-07-cron-logger` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule a recurring task for a specific user.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user ferro if it does not exist and set its (clientvm) - 10 pts

Create user ferro if it does not exist and set its password to cinder9.

---

## Task 02 - Configure a cron job for ferro that runs every 2 (clientvm) - 10 pts

Configure a cron job for ferro that runs every 2 minutes and logs the message "Lab 07 running" with logger.

## Hints
- Use crontab -e -u ferro.
- Leave crond enabled and running.

## Validation Commands
```bash
crontab -l -u ferro | grep -Fqx '*/2 * * * * logger "Lab 07 running"'
systemctl is-enabled crond | grep -qx enabled && systemctl is-active crond | grep -qx active
```
