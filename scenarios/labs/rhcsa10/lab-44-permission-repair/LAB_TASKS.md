# RHCSA 10 Lab 44: Permission Repair

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-44-permission-repair` |
| Mode | Lab |
| Scope | server |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Diagnose and repair file permission problems.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /srv/repair10/report.txt (server) - 10 pts

On server, create /srv/repair10/report.txt.

---

## Task 02 - Make the file readable and writable by owner and group, and unreadable b (server) - 10 pts

On server, make the file readable and writable by owner and group, and unreadable by others.

---

## Task 03 - Ensure the parent directory allows group traversal (server) - 10 pts

On server, ensure the parent directory allows group traversal.
