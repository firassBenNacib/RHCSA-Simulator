# Lab 16: Additional Swap Space - Lab Solution
Scenario ID: lab-16-swap-space
Mode: Lab
Time limit: 25 minutes
Objectives: storage-lvm

Add a persistent swap partition on an extra disk.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
fdisk /dev/sdb
# create a 400M partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
```

Verification
```bash
swapon --show
lsblk -f /dev/sdb
```
