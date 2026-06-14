# Lab 36: Persistent NFS Direct Mount

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-36-nfs-direct-mount` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | filesystems-and-autofs, storage-lvm |

Mount a remote NFS export persistently using /etc/fstab.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Server NFS Export (server) - 10 pts

On server, create /exports/direct36, place nfs36.txt in it, export it read-only to 192.168.122.0/24, and enable nfs-server.

---

## Task 02 - Client Persistent NFS Mount (client) - 10 pts

On client, mount 192.168.122.3:/exports/direct36 persistently at /mnt/direct36 with ro,sync options and verify nfs36.txt is readable.
