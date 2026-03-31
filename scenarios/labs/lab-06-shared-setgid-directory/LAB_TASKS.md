# Lab 06: Shared Setgid Directory - Lab Tasks
Scenario ID: lab-06-shared-setgid-directory
Mode: Lab
Time limit: 25 minutes
Objectives: filesystems-and-autofs

Create a collaborative directory that preserves group ownership.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create /shared/analysts with group ownership of analystsx and allow access only to root and members of analystsx.

## Task 02 - Part 02 (clientvm)
Set the directory so new files inherit the analystsx group automatically.

## Task 03 - Part 03 (clientvm)
Verify the final directory permissions.

Hints
1. The group analystsx already exists for this lab.
2. The directory must keep the setgid bit.

Checks
```bash
ls -ld /shared/analysts
```
