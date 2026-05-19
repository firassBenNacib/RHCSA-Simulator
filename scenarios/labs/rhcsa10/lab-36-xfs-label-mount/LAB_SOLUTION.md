# RHCSA 10 Lab 36: XFS Label Mount

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-36-xfs-label-mount` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | storage-lvm |

Create a labeled filesystem and mount persistently.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create an XFS filesystem on /dev/sdb1 labeled RHCSA10DATA (client) - 10 pts

```bash
parted -s /dev/sdb mklabel gpt mkpart primary xfs 1MiB 512MiB
partprobe /dev/sdb || true
udevadm settle
mkfs.xfs -f -L RHCSA10DATA /dev/sdb1
```

---

## Task 02 - Create mount point /mnt/rhcsa10data (client) - 10 pts

```bash
mkdir -p /mnt/rhcsa10data
```

---

## Task 03 - Mount it persistently by label with default options (client) - 10 pts

```bash
echo 'LABEL=RHCSA10DATA /mnt/rhcsa10data xfs defaults 0 0' >> /etc/fstab
mount -a
```
