# RHCSA 10 Lab 38: LVM Create

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-38-lvm-create` |
| Mode | Lab |
| Scope | client |
| Time limit | 40 minutes |
| Objectives | storage-lvm |

Create and mount a logical volume.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create physical volume /dev/sdb (client) - 10 pts

```bash
wipefs -a /dev/sdb >/dev/null 2>&1 || true
sgdisk --zap-all /dev/sdb >/dev/null 2>&1 || true
pvcreate -ff -y /dev/sdb
```

---

## Task 02 - Create volume group vg10 (client) - 10 pts

```bash
vgcreate vg10 /dev/sdb
```

---

## Task 03 - Create a 384 MiB logical volume lvdata formatted with XFS and mounted at (client) - 10 pts

```bash
lvcreate -L 384M -n lvdata vg10
mkfs.xfs -f /dev/vg10/lvdata
mkdir -p /mnt/lvdata10
echo '/dev/vg10/lvdata /mnt/lvdata10 xfs defaults 0 0' >> /etc/fstab
mount -a
```
