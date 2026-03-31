# Lab 02: Root Password Recovery - Lab Tasks
Scenario ID: lab-02-root-recovery
Mode: Lab
Time limit: 40 minutes
Objectives: boot-and-recovery

Recover root access through the bootloader and restore normal access on clientvm.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Recover root access on clientvm from the console and set the root password to redhat.

## Task 02 - Part 02 (clientvm)
After the system boots normally, confirm that SELinux relabeling completed and root can log in again.

## Task 03 - Part 03 (clientvm)
Leave SSH password authentication working for root and admin.

Hints
1. Use the rescue edit path with rd.break.
2. Remember to touch /.autorelabel before exiting the chroot.

Checks
```bash
getenforce
ls -Z /root | head
ssh -o StrictHostKeyChecking=no root@clientvm true
```
