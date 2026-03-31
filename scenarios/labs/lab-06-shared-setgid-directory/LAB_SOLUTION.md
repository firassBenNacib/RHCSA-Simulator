# Lab 06: Shared Setgid Directory

## Lab Solution
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

#### Command Flow
```bash
mkdir -p /shared/analysts
chgrp analystsx /shared/analysts
chmod 2770 /shared/analysts
```

---

### Task 02 — Set the directory so new files inherit the analystsx…
**System:** clientvm

#### Command Flow
```bash
touch /shared/analysts/probe.txt
ls -l /shared/analysts/probe.txt
```

---

### Task 03 — Verify the final directory permissions
**System:** clientvm

#### Command Flow
```bash
ls -ld /shared/analysts
```

---

### Verification
```bash
ls -ld /shared/analysts
```
