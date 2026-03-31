# Lab 47: Per-User Password Aging

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-47-user-password-aging` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Adjust password aging for an existing user account with chage.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create user aging47 with password redhat if it does…
**System:** clientvm

Create user aging47 with password redhat if it does not already exist.

---

### Task 02 — Configure aging47 with a maximum password age of 30…
**System:** clientvm

Configure aging47 with a maximum password age of 30 days, a minimum age of 2 days, and a warning period of 7 days.

---

### Task 03 — Force aging47 to change the password at the next login
**System:** clientvm

Force aging47 to change the password at the next login.

### Hints
- Use chage, not manual edits to /etc/shadow.

### Validation Commands
```bash
chage -l aging47
```
