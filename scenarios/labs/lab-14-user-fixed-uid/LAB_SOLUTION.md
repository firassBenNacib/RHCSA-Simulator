# Lab 14: User With Fixed UID

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-14-user-fixed-uid` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | users-sudo-ssh |

Create a local user with a specific UID.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
useradd -u 4111 choubix
passwd choubix
# enter: redhat
id choubix
```

---

### Verification
```bash
id choubix
```
