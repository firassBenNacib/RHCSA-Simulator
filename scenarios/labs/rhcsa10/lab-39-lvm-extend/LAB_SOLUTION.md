# RHCSA 10 Lab 39: LVM Extend

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-lvm-extend` |
| Mode | Lab |
| Scope | client |
| Time limit | 30 minutes |
| Objectives | storage-lvm |

Extend an existing logical volume and filesystem.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create volume group grow10 on /dev/sdb (client) - 10 pts

```bash
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
pvcreate -ff -y /dev/sdb
vgcreate grow10 /dev/sdb
```

---

## Task 02 - Create logical volume growlv with size 384 MiB and XFS filesystem mounte (client) - 10 pts

```bash
lvcreate -L 384M -n growlv grow10
mkfs.xfs -f /dev/grow10/growlv
mkdir -p /mnt/grow10
mount /dev/grow10/growlv /mnt/grow10
```

---

## Task 03 - Extend the logical volume and filesystem to at least 512 MiB (client) - 10 pts

```bash
lvextend -L 512M -r /dev/grow10/growlv
```
