# Lab 15: LVM Creation And Mount

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-15-lvm-create-mount` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | storage-lvm |

Create a new volume group and logical volume and mount it persistently.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - On /dev/sdb, create an LVM partition, then create (clientvm) - 10 pts

```bash
fdisk /dev/sdb
# create a GPT LVM partition for the remaining disk space
partprobe /dev/sdb
pvcreate /dev/sdb1
vgcreate -s 8M wgroupx /dev/sdb1
lvcreate -n wsharex -l 50 wgroupx
```

---

## Task 02 - Create logical volume wsharex with 50 extents, (clientvm) - 10 pts

```bash
mkfs.ext4 /dev/wgroupx/wsharex
mkdir -p /mnt/wsharex
blkid /dev/wgroupx/wsharex
vim /etc/fstab
UUID=<uuid-of-wsharex> /mnt/wsharex ext4 defaults 0 0
mount -a
findmnt /mnt/wsharex
```
