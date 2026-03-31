# Lab 09: Tar Archive With Bzip2

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-09-archive-bzip2` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Create a compressed archive in bzip2 format.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Create /root/myetcbackup.tar.bz2 containing the /etc directory.

### Hints
- Use tar with bzip2 compression directly.

### Checks
```bash
tar -tjf /root/myetcbackup.tar.bz2 | head
```
