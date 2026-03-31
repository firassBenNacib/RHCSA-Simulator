# Lab 27: At Job Scheduling

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-27-at-job` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule a one time task with at and verify that the at daemon is enabled.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create the user atuser27 and set its password to…
**System:** clientvm

#### Command Flow
```bash
useradd -m atuser27
passwd atuser27
# enter: redhat
```

---

### Task 02 — Enable and start the atd service
**System:** clientvm

#### Command Flow
```bash
systemctl enable --now atd
```

---

### Task 03 — schedule a one-time at job that appends the text AT27…
**System:** clientvm

#### Command Flow
```bash
runuser -l atuser27 -c "echo 'echo AT27 OK >> /home/atuser27/at27.log' | at now + 2 minutes"
atq
```

---

### Verification
```bash
systemctl is-enabled atd
systemctl is-active atd
atq
```
