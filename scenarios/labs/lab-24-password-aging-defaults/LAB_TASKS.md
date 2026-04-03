# Lab 24: Password Aging Defaults

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-24-password-aging-defaults` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure stronger new-user aging defaults, including inactive days.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set password aging defaults in login.defs (clientvm) - 10 pts

Configure the system defaults for newly created local users so that the maximum password age is 60 days, the minimum age is 7 days, and the warning period is 10 days.

---

## Task 02 - Set the useradd inactive default (clientvm) - 10 pts

Configure the default inactive period for newly created local users to 15 days.

---

## Task 03 - Create drift24 with the inherited defaults (clientvm) - 10 pts

Create the user drift24, set its password to cinder9, and ensure the user inherits the default password aging policy.

## Hints
- PASS_MAX_DAYS, PASS_MIN_DAYS, and PASS_WARN_AGE live in /etc/login.defs.
- Use useradd -D to set and verify the inactive default.

## Validation Commands
```bash
grep -Eq '^PASS_MAX_DAYS[[:space:]]+60$' /etc/login.defs && grep -Eq '^PASS_MIN_DAYS[[:space:]]+7$' /etc/login.defs && grep -Eq '^PASS_WARN_AGE[[:space:]]+10$' /etc/login.defs
useradd -D | grep -Eq '^INACTIVE=15$'
getent passwd drift24 >/dev/null && chage -l drift24 | grep -Fq 'Maximum number of days between password change			: 60' && chage -l drift24 | grep -Fq 'Minimum number of days between password change			: 7' && chage -l drift24 | grep -Fq 'Number of days of warning before password expires		: 10'
```
