# RHCSA 10 Lab 20: SELinux Mode

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-20-selinux-mode` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | selinux-and-default-perms |

Set SELinux enforcing mode persistently.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set SELinux to enforcing mode immediately (client) - 10 pts

```bash
setenforce 1
```

---

## Task 02 - Configure SELinux to boot in enforcing mode (client) - 20 pts

```bash
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
getenforce
grep '^SELINUX=' /etc/selinux/config
```
