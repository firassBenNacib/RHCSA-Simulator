# RHCSA 10 Lab 44: Permission Repair

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-44-permission-repair` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Diagnose and repair file permission problems.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /srv/repair10/report.txt (client) - 10 pts

```bash
mkdir -p /srv/repair10
touch /srv/repair10/report.txt
```

---

## Task 02 - Make the file readable and writable by owner and group, and unreadable b (client) - 10 pts

```bash
chmod 660 /srv/repair10/report.txt
```

---

## Task 03 - Ensure the parent directory allows group traversal (client) - 10 pts

```bash
chmod 770 /srv/repair10
```
