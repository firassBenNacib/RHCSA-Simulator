# Lab 37: Services and Default Target

## Lab Solution
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

```bash
systemctl set-default multi-user.target
```

---

## Task 02 - Enable rsyslog on servervm (servervm) - 10 pts

```bash
systemctl enable --now rsyslog
```

---

## Task 03 - Disable postfix on servervm if present (servervm) - 10 pts

```bash
rpm -q postfix >/dev/null 2>&1 && systemctl disable --now postfix || true
```

---

## Verification
```bash
ssh admin@servervm systemctl get-default | grep -qx multi-user.target
ssh admin@servervm systemctl is-enabled rsyslog | grep -qx enabled && ssh admin@servervm systemctl is-active rsyslog | grep -qx active
ssh admin@servervm sh -lc 'rpm -q postfix >/dev/null 2>&1 || exit 0; systemctl is-enabled postfix 2>/dev/null | grep -qx disabled && systemctl is-active postfix 2>/dev/null | grep -qx inactive'
```
