# Lab 37: Services and Default Target

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-37-services-default-target` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | system-services-and-targets, boot-and-recovery |

Control the default boot target and manage system services in a persistent way.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Configure clientvm to boot into multi-user.target by default.

---

## Task 02 — Part 02
**System:** clientvm

Ensure the rsyslog service is enabled and running.

---

## Task 03 — Part 03
**System:** clientvm

If postfix is installed, disable it and stop it.

### Hints
- Use systemctl for both target and service management.

### Checks
```bash
systemctl get-default | grep -qx multi-user.target
systemctl is-enabled rsyslog | grep -qx enabled
systemctl is-active rsyslog | grep -qx active
```
