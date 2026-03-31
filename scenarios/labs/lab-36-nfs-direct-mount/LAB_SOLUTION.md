# Lab 36: Persistent NFS Direct Mount

## Lab Solution
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

#### Commands
```bash
mkdir -p /mnt/direct36
vim /etc/fstab
192.168.122.3:/exports/direct36 /mnt/direct36 nfs ro,sync 0 0
:wq
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
mount -a
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
ls /mnt/direct36
```

---

### Verification
```bash
grep -q "/mnt/direct36" /etc/fstab
mountpoint -q /mnt/direct36
test -f /mnt/direct36/nfs36.txt
```
