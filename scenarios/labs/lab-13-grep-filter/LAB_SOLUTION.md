# Lab 13: Text Filtering With Grep

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-13-grep-filter` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Extract matching lines from a seeded words file.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
grep "ich" /usr/share/dict/words > /root/lines
```

---

### Verification
```bash
grep ich /root/lines
```
