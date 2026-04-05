# Lab 09: Tar Archive With Bzip2

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-09-archive-bzip2` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Create a compressed archive in bzip2 format.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /root/myetcbackup.tar.bz2 containing the (clientvm) - 10 pts

```bash
tar -cjf /root/myetcbackup.tar.bz2 /etc
```
