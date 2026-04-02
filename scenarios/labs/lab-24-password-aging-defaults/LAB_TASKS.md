# Lab 24: Password Aging Defaults

## Lab Tasks
## Overview
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

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure the system defaults for newly created (clientvm) - 10 pts

Configure the system defaults for newly created local users with the following values:

- **Pass_Max_Days:** 45
- **Pass_Min_Days:** 2
- **Pass_Warn_Age:** 10

---

## Task 02 - Create the user drift24, set its password to (clientvm) - 10 pts

Create the user drift24, set its password to cinder9, and ensure the user inherits the default password aging policy.

## Hints
- Edit /etc/login.defs directly.
- Use chage -l to verify the new account settings.

## Validation Commands
```bash
grep -Eq '^[[:space:]]*PASS_MAX_DAYS[[:space:]]+45[[:space:]]*$' /etc/login.defs && grep -Eq '^[[:space:]]*PASS_MIN_DAYS[[:space:]]+2[[:space:]]*$' /etc/login.defs && grep -Eq '^[[:space:]]*PASS_WARN_AGE[[:space:]]+10[[:space:]]*$' /etc/login.defs
chage -l drift24 | grep -Eq 'Minimum number of days between password change[^0-9]*2$' && chage -l drift24 | grep -Eq 'Maximum number of days between password change[^0-9]*45$' && chage -l drift24 | grep -Eq 'Number of days of warning before password expires[^0-9]*10$'
```
