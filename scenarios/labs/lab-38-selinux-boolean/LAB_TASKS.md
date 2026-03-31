# Lab 38: SELinux Boolean

## Lab Tasks
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

On clientvm, configure the SELinux boolean httpd_can_network_connect so it is enabled persistently.

---

## Task 02 — Part 02
**System:** clientvm

SELinux must remain in enforcing mode.

### Hints
- Use a persistent SELinux boolean command.

### Checks
```bash
getsebool httpd_can_network_connect | grep -q "--> on"
getenforce | grep -qx Enforcing
```
