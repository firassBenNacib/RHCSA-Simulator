# Lab 07: Cron Scheduling

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-07-cron-logger` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule a recurring task for a specific user.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Create user natcron if it does not exist and set its password to redhat.

---

## Task 02 — Part 02
**System:** clientvm

Configure a cron job for natcron that runs every 2 minutes and logs the message "Lab 07 running" with logger.

### Hints
- Use crontab -e -u natcron.
- Leave crond enabled and running.

### Checks
```bash
crontab -l -u natcron
systemctl status crond --no-pager
```
