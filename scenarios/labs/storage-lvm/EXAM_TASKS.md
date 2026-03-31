# Local Storage And LVM - Exam Tasks
Scenario ID: storage-lvm
Mode: Exam
Time limit: 60 minutes
Objectives: storage-lvm

Practice RHCSA v9 partitioning, LVM creation, swap, and persistent filesystem mounts on the attached data disks.

## Task 01 - Volume Group And labdata LV (clientvm) - 25 pts
Create volume group rhcsa_vg on the attached data disks.

## Task 02 - XFS Data Mount (clientvm) - 30 pts
Create and mount an XFS logical volume labdata at /srv/labdata.

## Task 03 - Swap Logical Volume (clientvm) - 20 pts
Create and activate a 256 MiB swap logical volume named labswap.

## Task 04 - ext4 Filesystem Mount (clientvm) - 25 pts
Create and mount a persistent ext4 filesystem at /mnt/labext4.
