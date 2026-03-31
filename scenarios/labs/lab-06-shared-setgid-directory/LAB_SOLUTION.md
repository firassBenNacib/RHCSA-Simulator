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

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
mkdir -p /shared/analysts
chgrp analystsx /shared/analysts
chmod 2770 /shared/analysts
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
touch /shared/analysts/probe.txt
ls -l /shared/analysts/probe.txt
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
ls -ld /shared/analysts
```

---

### Verification
```bash
ls -ld /shared/analysts
```
