# Lab 12: Find And Copy With Structure

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-12-find-copy-preserve` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | essential-tools |

Locate recent files owned by a user and copy them while preserving directories.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
find /opt/lab12/source -type f -user natfind -mtime -1 -exec cp --parents {} /root/natfind-files \;
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
find /root/natfind-files -type f | sort
```

---

### Verification
```bash
find /root/natfind-files -type f | sort
```
