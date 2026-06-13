# Lab 36: Persistent NFS Direct Mount

## Lab Solution
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
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Persistently mount the NFS export (client) - 10 pts

```bash
mkdir -p /mnt/direct36
vim /etc/fstab
192.168.122.3:/exports/direct36 /mnt/direct36 nfs ro,sync 0 0
```

---

## Task 02 - Mount the NFS export and read the file (client) - 20 pts

```bash
# On client
dnf install -y nfs-utils
systemctl enable --now nfs-client.target || true
mount /mnt/direct36 || mount -a
for attempt in 1 2 3 4 5; do mountpoint -q /mnt/direct36 && test -f /mnt/direct36/nfs36.txt && break; sleep 2; done
ls /mnt/direct36
```
