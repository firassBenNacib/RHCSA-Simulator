# Lab 36: Persistent NFS Direct Mount

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-36-nfs-direct-mount` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | filesystems-and-autofs, storage-lvm |

Mount a remote NFS export persistently using /etc/fstab.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Persistently mount the NFS export (client) - 10 pts

Persistently mount the NFS export 192.168.122.3:/exports/direct36 on client at /mnt/direct36.

---

## Task 02 - Mount the NFS export and read the file (client) - 20 pts

On client, use the mount options ro,sync, mount it now, and ensure the file nfs36.txt can be read from the mount point.
