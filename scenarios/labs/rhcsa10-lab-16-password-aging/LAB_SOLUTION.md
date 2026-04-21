# RHCSA 10 Lab 16: Password Aging

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-16-password-aging` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | users-sudo-ssh |

Adjust password aging for a local user.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create user aging10 and set password cinder9 (client) - 10 pts

```bash
useradd aging10
passwd aging10
# enter: cinder9
```

---

## Task 02 - Set maximum password age to 60 days (client) - 10 pts

```bash
chage -M 60 aging10
```

---

## Task 03 - Set password warning period to 7 days (client) - 10 pts

```bash
chage -W 7 aging10
```
