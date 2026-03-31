# Lab 12: Find And Copy With Structure - Lab Tasks
Scenario ID: lab-12-find-copy-preserve
Mode: Lab
Time limit: 25 minutes
Objectives: essential-tools

Locate recent files owned by a user and copy them while preserving directories.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Find all files owned by natfind and modified in the last 24 hours under /opt/lab12/source.

## Task 02 - Part 02 (clientvm)
Copy them to /root/natfind-files and preserve the original directory structure.

Hints
1. Use find with a time test and --parents or an equivalent method.
2. Only copy regular files.

Checks
```bash
find /root/natfind-files -type f | sort
```
