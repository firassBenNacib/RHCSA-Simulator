# RHCSA 10 Lab 44: Permission Repair

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-44-permission-repair` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Diagnose and repair file permission problems.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - create /srv/repair10/report.txt (server) - 10 pts

```bash
mkdir -p /srv/repair10
touch /srv/repair10/report.txt
```

---

## Task 02 - make the file readable and writable by owner and group, and unreadable b (server) - 10 pts

```bash
chmod 660 /srv/repair10/report.txt
```

---

## Task 03 - ensure the parent directory allows group traversal (server) - 10 pts

```bash
chmod 770 /srv/repair10
```
