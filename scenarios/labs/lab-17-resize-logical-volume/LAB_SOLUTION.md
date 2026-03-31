# Lab 17: Resize A Logical Volume - Lab Solution
Scenario ID: lab-17-resize-logical-volume
Mode: Lab
Time limit: 30 minutes
Objectives: storage-lvm

Extend an existing logical volume without losing data.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
lsblk -f
lvs
lvextend -L 320M /dev/reviewvg/reviewlv
blkid /dev/reviewvg/reviewlv
# if the filesystem is ext4, run resize2fs /dev/reviewvg/reviewlv
# if the filesystem is xfs, run xfs_growfs /mnt/reviewlv
```

Verification
```bash
lvs
df -hT /mnt/reviewlv
```
