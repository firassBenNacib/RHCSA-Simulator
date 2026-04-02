# Lab 38: SELinux Boolean

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-38-selinux-boolean` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | selinux-and-default-perms |

Modify a SELinux boolean persistently without changing enforcing mode.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - configure the SELinux boolean (clientvm) - 10 pts

```bash
setsebool -P httpd_can_network_connect on
```

---

## Task 02 - SELinux must remain in enforcing mode (clientvm) - 10 pts

```bash
getenforce
getsebool httpd_can_network_connect
```

---

## Verification
```bash
getsebool httpd_can_network_connect | grep -q "--> on"
getenforce | grep -qx Enforcing
```
