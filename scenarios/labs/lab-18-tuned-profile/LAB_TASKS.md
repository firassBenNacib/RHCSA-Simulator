# Lab 18: Tuned Recommended Profile

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-18-tuned-profile` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | processes-logs-tuning |

Apply the system recommended tuned profile.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Apply the recommended tuned profile and leave it (clientvm) - 10 pts

Apply the recommended tuned profile and leave it active after reboot.

## Hints
- Use tuned-adm recommended to see the target profile.

## Validation Commands
```bash
rec="$(tuned-adm recommended | awk '{print $1}')"; act="$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\1/')"; test -n "$rec" && test "$act" = "$rec"
```
