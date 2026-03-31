# Lab 18: Tuned Recommended Profile

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-18-tuned-profile` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | processes-logs-tuning |

Apply the system recommended tuned profile.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Apply the recommended tuned profile and leave it active after reboot.

### Hints
- Use tuned-adm recommended to see the target profile.

### Checks
```bash
tuned-adm active
tuned-adm recommended
```
