# RHCSA 10 Lab 21: Restore SELinux Context

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-21-selinux-restorecon` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Restore default SELinux file contexts.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /var/www/html/rhcsa10.html containing RHCSA10 (client) - 10 pts

```bash
echo RHCSA10 > /var/www/html/rhcsa10.html
```

---

## Task 02 - Set an incorrect context on the file (client) - 10 pts

```bash
chcon -t user_tmp_t /var/www/html/rhcsa10.html
```

---

## Task 03 - Restore the default context with restorecon (client) - 10 pts

```bash
restorecon -v /var/www/html/rhcsa10.html
```
