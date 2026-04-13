# Lab 18: Tuned Recommended Profile

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-18-tuned-profile` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | processes-logs-tuning |

Apply the system recommended tuned profile.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Apply the recommended tuned profile and leave it (clientvm) - 10 pts

```bash
tuned-adm recommend
rec="$(tuned-adm recommend | awk '{print $1}')"
tuned-adm profile "$rec"
tuned-adm active
```
