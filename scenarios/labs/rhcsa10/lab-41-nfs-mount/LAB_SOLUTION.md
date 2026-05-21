# RHCSA 10 Lab 41: NFS Direct Mount

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-41-nfs-mount` |
| Mode | Lab |
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

## Task 01 - create mount point /mnt/serverdirect10 (client) - 10 pts

```bash
mkdir -p /mnt/serverdirect10
```

---

## Task 02 - mount server:/exports/direct at /mnt/serverdirect10 (client) - 10 pts

```bash
mount -t nfs server:/exports/direct /mnt/serverdirect10
```

---

## Task 03 - make the mount persistent across reboots (client) - 10 pts

```bash
grep -Eq '^server:/exports/direct[[:space:]]+/mnt/serverdirect10[[:space:]]+nfs' /etc/fstab || echo 'server:/exports/direct /mnt/serverdirect10 nfs defaults,_netdev 0 0' >> /etc/fstab
```
