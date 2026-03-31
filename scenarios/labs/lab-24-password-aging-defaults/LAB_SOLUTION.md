# Lab 24: Password Aging Defaults

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-24-password-aging-defaults` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure default password aging for newly created local users through login.defs.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Configure the system defaults for newly created local…
**System:** clientvm

#### Command Flow
```bash
vim /etc/login.defs
PASS_MAX_DAYS   45
PASS_MIN_DAYS   2
PASS_WARN_AGE   10
```

---

### Task 02 — Create the user aging24, set its password to redhat,…
**System:** clientvm

#### Command Flow
```bash
useradd -m aging24
passwd aging24
# enter: redhat
chage -l aging24
```

---

### Verification
```bash
grep -E '^PASS_(MAX_DAYS|MIN_DAYS|WARN_AGE)' /etc/login.defs
chage -l aging24
```
