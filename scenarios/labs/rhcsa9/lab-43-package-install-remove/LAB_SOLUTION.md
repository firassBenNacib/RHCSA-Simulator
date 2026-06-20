# Lab 43: Package Install and Remove

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-43-package-install-remove` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Install packages from the prepared local repositories and remove the one that is no longer needed.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client package install and remove (client) - 10 pts

```bash
dnf install -y tree dos2unix
dnf remove -y dos2unix
rpm -q tree
```

---

## Task 02 - Server package install and remove (server) - 10 pts

```bash
dnf install -y lsof dos2unix
dnf remove -y dos2unix
rpm -q lsof
```
