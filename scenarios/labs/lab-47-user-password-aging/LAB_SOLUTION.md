# Lab 47: Per-User Password Aging

## Lab Solution
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

```bash
useradd cycle47
printf 'cycle47:cinder9
' | chpasswd
```

---

## Task 02 - Apply the requested password aging values (clientvm) - 10 pts

```bash
chage -M 30 -m 2 -W 7 cycle47
```

---

## Task 03 - Expire the password for the next login (clientvm) - 10 pts

```bash
chage -d 0 cycle47
```
