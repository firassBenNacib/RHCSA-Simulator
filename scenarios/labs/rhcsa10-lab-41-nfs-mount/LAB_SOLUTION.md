# RHCSA 10 Lab 41: NFS Direct Mount

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-41-nfs-mount` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | filesystems-and-autofs |

Mount a network filesystem persistently.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create mount point /mnt/serverdirect10 (server) - 10 pts

```bash
mkdir -p /mnt/serverdirect10
```

---

## Task 02 - Mount server:/exports/direct at /mnt/serverdirect10 (server) - 10 pts

```bash
mount -t nfs server:/exports/direct /mnt/serverdirect10
```

---

## Task 03 - Make the mount persistent across reboots (server) - 10 pts

```bash
echo 'server:/exports/direct /mnt/serverdirect10 nfs defaults,_netdev 0 0' >> /etc/fstab
```
