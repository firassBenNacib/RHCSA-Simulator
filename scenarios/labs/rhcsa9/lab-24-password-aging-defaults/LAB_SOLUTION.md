# Lab 24: Password Aging Defaults

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-24-password-aging-defaults` |
| Mode | Lab |
| Scope | client |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure stronger new-user aging defaults, including inactive days.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set password aging defaults in login.defs (client) - 10 pts

```bash
vim /etc/login.defs
PASS_MAX_DAYS 60
PASS_MIN_DAYS 7
PASS_WARN_AGE 10
```

---

## Task 02 - Set the useradd inactive default (client) - 10 pts

```bash
useradd -D -f 15
```

---

## Task 03 - Create drift24 with the inherited defaults (client) - 10 pts

```bash
useradd drift24
echo 'drift24:cinder9' | chpasswd
```
