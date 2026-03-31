# Lab 16: Additional Swap Space - Lab Tasks
Scenario ID: lab-16-swap-space
Mode: Lab
Time limit: 25 minutes
Objectives: storage-lvm

Add a persistent swap partition on an extra disk.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create a 400 MiB swap partition on /dev/sdb, enable it, and make it persistent.

Hints
1. Use GPT partition type 19 for swap.
2. Use a UUID entry in /etc/fstab.

Checks
```bash
swapon --show
lsblk -f /dev/sdb
```
