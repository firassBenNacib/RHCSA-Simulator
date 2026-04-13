# Lab 15: LVM Creation And Mount

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-15-lvm-create-mount` |
| Mode | Lab |
| Time limit | 40 minutes |
| Objectives | storage-lvm |

Create a new volume group and logical volume and mount it persistently.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - On /dev/sdb, create an LVM partition, then create (clientvm) - 10 pts

On /dev/sdb, create an LVM partition, then create volume group wgroupx with physical extent size 8 MiB.

---

## Task 02 - Create logical volume wsharex with 50 extents, (clientvm) - 10 pts

Create logical volume wsharex with 50 extents, format it as ext4, and mount it persistently on /mnt/wsharex.
