# Local Storage And LVM - Lab Tasks
Scenario ID: storage-lvm
Mode: Lab
Time limit: 60 minutes
Objectives: storage-lvm

Practice RHCSA v9 partitioning, LVM creation, swap, and persistent filesystem mounts on the attached data disks.

## Task 01 - Volume Group And labdata LV (clientvm) - 10 pts
Use the attached data disks to create a volume group named rhcsa_vg and a logical volume named labdata sized to 512 MiB.

## Task 02 - XFS Data Mount (clientvm) - 15 pts
Format labdata with XFS and mount it persistently at /srv/labdata.

## Task 03 - Swap Logical Volume (clientvm) - 10 pts
Create an additional 256 MiB swap logical volume named labswap and activate it persistently.

## Task 04 - ext4 Filesystem Mount (clientvm) - 10 pts
Create a separate 300 MiB ext4 filesystem on remaining space and mount it persistently at /mnt/labext4.

## Task 05 - Reboot Persistence Check (clientvm) - 5 pts
Ensure all new storage survives reboot.

Hints
1. Use lsblk first to identify the two attached data disks.
2. You can use one or both disks as physical volumes.
3. Use /etc/fstab entries by UUID or device mapper path for persistence.

Checks
```bash
pvs
vgs
lvs
findmnt /srv/labdata
findmnt /mnt/labext4
swapon --show
```
