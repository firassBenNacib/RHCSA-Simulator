# RHCSA 10 Lab 46: Local RPM Install

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-46-package-file-install` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 20 minutes |
| Objectives | software-management |

Install software from a local RPM file.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Install the local tree RPM from /var/www/html/repo or the mounted ISO wi (client) - 10 pts

```bash
dnf install -y --disablerepo='*' --enablerepo=rhcsa-baseos --enablerepo=rhcsa-appstream tree
rpm -q tree
```
