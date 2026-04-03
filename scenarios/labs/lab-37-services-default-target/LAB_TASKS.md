# Lab 37: Services and Default Target

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-37-services-default-target` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, boot-and-recovery |

Manage the default target and key services on servervm.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set the default boot target on servervm (clientvm) - 10 pts

Configure servervm to boot into multi-user.target by default.

---

## Task 02 - Enable rsyslog on servervm (servervm) - 10 pts

Ensure the rsyslog service is enabled and running on servervm.

---

## Task 03 - Disable postfix on servervm if present (servervm) - 10 pts

If postfix is installed on servervm, disable it and stop it.

## Hints
- This lab belongs on servervm, not clientvm.
- Treat postfix as conditional: only act if it is installed.

## Validation Commands
```bash
ssh admin@servervm systemctl get-default | grep -qx multi-user.target
ssh admin@servervm systemctl is-enabled rsyslog | grep -qx enabled && ssh admin@servervm systemctl is-active rsyslog | grep -qx active
ssh admin@servervm sh -lc 'rpm -q postfix >/dev/null 2>&1 || exit 0; systemctl is-enabled postfix 2>/dev/null | grep -qx disabled && systemctl is-active postfix 2>/dev/null | grep -qx inactive'
```
