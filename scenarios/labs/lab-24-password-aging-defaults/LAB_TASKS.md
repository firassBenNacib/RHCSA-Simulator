# Lab 24: Password Aging Defaults

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-24-password-aging-defaults` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure default password aging for newly created local users through login.defs.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Configure the system defaults for newly created local users with the following values:

PASS_MAX_DAYS: 45
PASS_MIN_DAYS: 2
PASS_WARN_AGE: 10

---

## Task 02 — Part 02
**System:** clientvm

Create the user aging24, set its password to redhat, and ensure the user inherits the default password aging policy.

### Hints
- Edit /etc/login.defs directly.
- Use chage -l to verify the new account settings.

### Checks
```bash
grep -E '^PASS_(MAX_DAYS|MIN_DAYS|WARN_AGE)' /etc/login.defs
chage -l aging24
```
