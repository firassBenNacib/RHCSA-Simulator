# Lab 08: Autofs With NFS - Lab Tasks
Scenario ID: lab-08-autofs-nfs
Mode: Lab
Time limit: 40 minutes
Objectives: filesystems-and-autofs

Configure an indirect automount from servervm.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
On servervm, export /exports/netuser8. On clientvm, create user netuser8 with password redhat.

## Task 02 - Part 02 (clientvm)
Configure autofs on clientvm so /netdir/netuser8 is mounted on demand from servervm:/exports/netuser8.

## Task 03 - Part 03 (clientvm)
Leave the configuration persistent across reboot.

Hints
1. Use an indirect map.
2. The export already contains a file named welcome.txt.

Checks
```bash
showmount -e servervm
ls -l /netdir/netuser8
ls -l /netdir/netuser8/welcome.txt
```
