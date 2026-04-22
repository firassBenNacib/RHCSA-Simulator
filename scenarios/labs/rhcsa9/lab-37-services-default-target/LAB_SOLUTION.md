# Lab 37: Services and Default Target

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-37-services-default-target` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, boot-and-recovery |

Manage the default target and key services on server.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set the default boot target on server (server) - 10 pts

```bash
systemctl set-default multi-user.target
```

---

## Task 02 - Manage rsyslog and postfix on server (server) - 20 pts

```bash
systemctl enable --now rsyslog
rpm -q postfix >/dev/null 2>&1 && systemctl disable --now postfix || true
```
