# Lab 15: LVM Creation And Mount - Lab Tasks
Scenario ID: lab-15-lvm-create-mount
Mode: Lab
Time limit: 40 minutes
Objectives: storage-lvm

Create a new volume group and logical volume and mount it persistently.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
On /dev/sdb, create an LVM partition, then create volume group wgroupx with physical extent size 8 MiB.

## Task 02 - Part 02 (clientvm)
Create logical volume wsharex with 50 extents, format it as ext4, and mount it persistently on /mnt/wsharex.

Hints
1. Use GPT on /dev/sdb.
2. Use a UUID entry in /etc/fstab.

Checks
```bash
pvs
vgs
lvs
lsblk -f /dev/sdb
findmnt /mnt/wsharex
```
