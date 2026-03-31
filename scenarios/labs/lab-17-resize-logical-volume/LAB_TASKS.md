# Lab 17: Resize A Logical Volume

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-17-resize-logical-volume` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | storage-lvm |

Extend an existing logical volume without losing data.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Resize logical volume /dev/reviewvg/reviewlv so the final size is 320 MiB and the existing filesystem remains usable after reboot.

### Hints
- The logical volume already exists and is mounted on /mnt/reviewlv.
- Do not recreate the filesystem.

### Checks
```bash
lvs
df -hT /mnt/reviewlv
```
