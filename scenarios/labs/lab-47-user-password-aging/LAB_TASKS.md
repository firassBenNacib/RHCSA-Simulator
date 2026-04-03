# Lab 47: Per-User Password Aging

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-47-user-password-aging` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Apply per-user password aging settings without adding extra account noise.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create cycle47 (clientvm) - 10 pts

Create user cycle47 with password cinder9 if it does not already exist.

---

## Task 02 - Apply the requested password aging values (clientvm) - 10 pts

Configure cycle47 with a maximum password age of 30 days, a minimum age of 2 days, and a warning period of 7 days.

---

## Task 03 - Expire the password for the next login (clientvm) - 10 pts

Force cycle47 to change the password at the next login.

## Hints
- This lab is about chage, not about home-directory behavior.
- Use chage -d 0 to force a change at next login.

## Validation Commands
```bash
getent passwd cycle47 >/dev/null
chage -l cycle47 | grep -Fq 'Maximum number of days between password change			: 30' && chage -l cycle47 | grep -Fq 'Minimum number of days between password change			: 2' && chage -l cycle47 | grep -Fq 'Number of days of warning before password expires		: 7'
chage -l cycle47 | grep -Fq 'Last password change				: password must be changed'
```
