# RHCSA 10 Lab 17: User Defaults

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-17-user-defaults` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | users-sudo-ssh |

Configure default useradd settings.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set default inactive password period for new users to 14 days (client) - 10 pts

```bash
useradd -D -f 14
```

---

## Task 02 - Set default account expiration date to 2030-12-31 (client) - 10 pts

```bash
useradd -D -e 2030-12-31
```

---

## Task 03 - Verify the new useradd defaults (client) - 10 pts

```bash
useradd -D
```
