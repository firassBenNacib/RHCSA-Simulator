# RHCSA 10 Lab 42: Autofs

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-42-autofs` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | filesystems-and-autofs |

Configure automount for NFS exports.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - create the autofs parent mount point /remote10 (client) - 10 pts

On client, create the autofs parent mount point /remote10.

---

## Task 02 - configure /remote10/projects to automount server:/exports/autofs/project (client) - 10 pts

On client, configure /remote10/projects to automount server:/exports/autofs/projects.

---

## Task 03 - enable and start autofs (client) - 10 pts

On client, enable and start autofs.
