# RHCSA 10 Lab 41: NFS Direct Mount

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-41-nfs-mount` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 30 minutes |
| Objectives | filesystems-and-autofs |

Mount a network filesystem persistently.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create mount point /mnt/serverdirect10 (client) - 10 pts

On client, create mount point /mnt/serverdirect10.

---

## Task 02 - Configure NFS export and mount (client + server) - 10 pts

On client, mount server:/exports/direct at /mnt/serverdirect10.

---

## Task 03 - Make the mount persistent across reboots (client) - 10 pts

On client, make the mount persistent across reboots.
