# Lab 16: Additional Swap Space

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-16-swap-space` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | storage-lvm |

Add a persistent swap partition on an extra disk.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create a 400 MiB swap partition on /dev/sdb, enable (clientvm) - 10 pts

```bash
fdisk /dev/sdb
# create a 400M partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid-of-sdb1> swap swap defaults 0 0
swapon --show
```
