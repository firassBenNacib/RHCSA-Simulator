# Lab 06: Shared Setgid Directory

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-06-shared-setgid-directory` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | filesystems-and-autofs |

Create a collaborative directory that preserves group ownership.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create /shared/analysts with group ownership of…
**System:** clientvm

Create /shared/analysts with group ownership of analystsx and allow access only to root and members of analystsx.

---

### Task 02 — Set the directory so new files inherit the analystsx…
**System:** clientvm

Set the directory so new files inherit the analystsx group automatically.

---

### Task 03 — Verify the final directory permissions
**System:** clientvm

Verify the final directory permissions.

### Hints
- The group analystsx already exists for this lab.
- The directory must keep the setgid bit.

### Validation Commands
```bash
ls -ld /shared/analysts
```
