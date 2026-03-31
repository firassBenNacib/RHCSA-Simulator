# Lab 12: Find And Copy With Structure - Lab Solution
Scenario ID: lab-12-find-copy-preserve
Mode: Lab
Time limit: 25 minutes
Objectives: essential-tools

Locate recent files owned by a user and copy them while preserving directories.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
find /opt/lab12/source -type f -user natfind -mtime -1 -exec cp --parents {} /root/natfind-files \;
```

## Task 02 - Part 02 (clientvm)
```bash
find /root/natfind-files -type f | sort
```

Verification
```bash
find /root/natfind-files -type f | sort
```
