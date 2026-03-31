# Lab 38: SELinux Boolean

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-38-selinux-boolean` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | selinux-and-default-perms |

Modify a SELinux boolean persistently without changing enforcing mode.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
setsebool -P httpd_can_network_connect on
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
getenforce
getsebool httpd_can_network_connect
```

---

### Verification
```bash
getsebool httpd_can_network_connect | grep -q "--> on"
getenforce | grep -qx Enforcing
```
