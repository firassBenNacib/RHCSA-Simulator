# Lab 37: Services and Default Target

## Lab Solution
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

#### Commands
```bash
systemctl set-default multi-user.target
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
systemctl enable --now rsyslog
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
systemctl disable --now postfix
```

---

### Verification
```bash
systemctl get-default | grep -qx multi-user.target
systemctl is-enabled rsyslog | grep -qx enabled
systemctl is-active rsyslog | grep -qx active
```
