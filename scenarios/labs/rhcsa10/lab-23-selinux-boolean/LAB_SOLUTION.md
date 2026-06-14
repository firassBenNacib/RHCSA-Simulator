# RHCSA 10 Lab 23: SELinux Boolean

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-23-selinux-boolean` |
| Mode | Lab |
| Scope | server |
| Time limit | 15 minutes |
| Objectives | selinux-and-default-perms |

Set SELinux booleans persistently.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Persist SELinux boolean (server) - 10 pts

```bash
setsebool httpd_can_network_connect on
```

---

## Task 02 - Persist SELinux boolean (server) - 10 pts

```bash
setsebool -P httpd_can_network_connect on
semanage boolean -l | grep httpd_can_network_connect
```
