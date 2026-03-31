# Lab 09: Tar Archive With Bzip2 - Lab Solution
Scenario ID: lab-09-archive-bzip2
Mode: Lab
Time limit: 15 minutes
Objectives: essential-tools

Create a compressed archive in bzip2 format.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
tar -cjf /root/myetcbackup.tar.bz2 /etc
```

Verification
```bash
tar -tjf /root/myetcbackup.tar.bz2 | head
```
