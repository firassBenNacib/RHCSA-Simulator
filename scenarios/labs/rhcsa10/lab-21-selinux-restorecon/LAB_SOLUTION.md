# RHCSA 10 Lab 21: Restore SELinux Context

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-21-selinux-restorecon` |
| Mode | Lab |
| Scope | client |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Restore default SELinux file contexts.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Restore the default SELinux context on /var/www/html/rhcsa10.html (client) - 10 pts

```bash
restorecon -v /var/www/html/rhcsa10.html
ls -Z /var/www/html/rhcsa10.html
```
