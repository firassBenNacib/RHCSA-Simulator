# Lab 07: Cron Scheduling

## Lab Solution
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

#### Commands
```bash
id natcron || useradd -m natcron
passwd natcron
# enter: redhat
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
crontab -e -u natcron
*/2 * * * * logger "Lab 07 running"
systemctl enable --now crond
```

---

### Verification
```bash
crontab -l -u natcron
systemctl status crond --no-pager
```
