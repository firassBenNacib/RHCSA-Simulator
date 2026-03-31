# Lab 36: Persistent NFS Direct Mount

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-36-nfs-direct-mount` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | nfs-and-autofs, storage-lvm |

Mount a remote NFS export persistently using /etc/fstab.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Persistently mount the NFS export 192.168.122.3:/exports/direct36 on clientvm at /mnt/direct36.

---

## Task 02 — Part 02
**System:** clientvm

Use the mount options ro,sync.

---

## Task 03 — Part 03
**System:** clientvm

Ensure the mount is available after a reboot and that the file nfs36.txt can be read from the mount point.

### Hints
- Use /etc/fstab for persistence.
- Do not use autofs for this task.

### Checks
```bash
grep -q "/mnt/direct36" /etc/fstab
mountpoint -q /mnt/direct36
test -f /mnt/direct36/nfs36.txt
```
