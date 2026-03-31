# Lab 03: DNF Repository Configuration - Lab Tasks
Scenario ID: lab-03-dnf-repositories
Mode: Lab
Time limit: 40 minutes
Objectives: software-scheduling-time

Configure offline BaseOS and AppStream repositories on both systems.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
On clientvm and servervm, configure a persistent repository file that uses http://servervm/repo/BaseOS/ and http://servervm/repo/AppStream/.

## Task 02 - Part 02 (clientvm)
Disable GPG checking in that file and leave both repositories enabled.

## Task 03 - Part 03 (clientvm)
Verify that package metadata is available from both repositories on both systems.

Hints
1. You can use one repo file per system.
2. Use vim to type the repository file manually.

Checks
```bash
dnf repolist
ssh admin@servervm sudo dnf repolist
```
