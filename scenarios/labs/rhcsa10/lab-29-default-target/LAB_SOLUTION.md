# RHCSA 10 Lab 29: Default Target

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-29-default-target` |
| Mode | Lab |
| Scope | server |
| Time limit | 15 minutes |
| Objectives | boot-and-recovery |

Configure system boot target.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set the default systemd target to multi-user.target without rebooting (server) - 10 pts

```bash
systemctl set-default multi-user.target
systemctl get-default
```
