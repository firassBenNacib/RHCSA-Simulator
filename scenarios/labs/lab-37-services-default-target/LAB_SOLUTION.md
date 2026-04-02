# Lab 37: Services and Default Target

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-37-services-default-target` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, boot-and-recovery |

Control the default boot target and manage system services in a persistent way.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure clientvm to boot into multi-user.target (clientvm) - 10 pts

```bash
systemctl set-default multi-user.target
```

---

## Task 02 - Ensure the rsyslog service is enabled and running (clientvm) - 10 pts

```bash
systemctl enable --now rsyslog
```

---

## Task 03 - If postfix is installed, disable it and stop it (clientvm) - 10 pts

```bash
systemctl disable --now postfix
```

---

## Verification
```bash
systemctl get-default | grep -qx multi-user.target
systemctl is-enabled rsyslog | grep -qx enabled
systemctl is-active rsyslog | grep -qx active
```
