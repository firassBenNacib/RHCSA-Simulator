# Lab 17: Resize A Logical Volume

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-17-resize-logical-volume` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | storage-lvm |

Extend an existing logical volume without losing data.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Resize logical volume /dev/reviewvg/reviewlv so the (clientvm) - 10 pts

```bash
lsblk -f
lvs
lvextend -L 320M /dev/reviewvg/reviewlv
blkid /dev/reviewvg/reviewlv
# if the filesystem is ext4, run resize2fs /dev/reviewvg/reviewlv
# if the filesystem is xfs, run xfs_growfs /mnt/reviewlv
df -hT /mnt/reviewlv
```
