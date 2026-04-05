# Lab 43: Package Install And Remove

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-43-package-install-remove` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Install packages from the prepared local repositories and remove the one that is no longer needed.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Install tree and remove dos2unix (clientvm) - 20 pts

```bash
dnf install -y tree dos2unix
dnf remove -y dos2unix
rpm -q tree
```
