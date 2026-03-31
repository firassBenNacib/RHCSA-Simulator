# Lab 18: Tuned Recommended Profile

## Lab Solution
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

#### Commands
```bash
tuned-adm recommended
tuned-adm profile <recommended-profile>
tuned-adm active
```

---

### Verification
```bash
tuned-adm active
tuned-adm recommended
```
