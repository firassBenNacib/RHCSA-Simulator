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
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create cycle47 and set the password (clientvm) - 10 pts

Create user cycle47 and set the password to cinder9.

---

## Task 02 - Apply the requested password aging values (clientvm) - 10 pts

Configure cycle47 with a maximum password age of 30 days, a minimum age of 2 days, and a warning period of 7 days.

---

## Task 03 - Expire the password for the next login (clientvm) - 10 pts

Force cycle47 to change the password at the next login.
