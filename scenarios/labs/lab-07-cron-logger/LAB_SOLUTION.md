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

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create user natcron if it does not exist and set its…
**System:** clientvm

#### Command Flow
```bash
id natcron || useradd -m natcron
passwd natcron
# enter: redhat
```

---

### Task 02 — Configure a cron job for natcron that runs every 2…
**System:** clientvm

#### Command Flow
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
