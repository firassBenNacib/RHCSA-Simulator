# RHCSA 10 Lab 40: VFAT Filesystem

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-40-vfat-filesystem` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | storage-lvm |

Create and mount a VFAT filesystem.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create a 256 MiB partition on /dev/sdb (client) - 10 pts

```bash
parted -s /dev/sdb mklabel gpt mkpart primary fat32 1MiB 257MiB
```

---

## Task 02 - Format it as VFAT with label RHCSA10VFAT (client) - 10 pts

```bash
mkfs.vfat -n RHCSA10VFAT /dev/sdb1
```

---

## Task 03 - Mount it persistently at /mnt/vfat10 (client) - 10 pts

```bash
mkdir -p /mnt/vfat10
echo 'LABEL=RHCSA10VFAT /mnt/vfat10 vfat defaults 0 0' >> /etc/fstab
mount -a
```
