# Lab 13: Text Filtering With Grep

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-13-grep-filter` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Extract matching lines from a seeded words file.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — From /usr/share/dict/words, extract the lines…
**System:** clientvm

From /usr/share/dict/words, extract the lines containing ich and save the result to /root/lines.

### Hints
- The words file for this lab is preseeded if it was not present before.

### Validation Commands
```bash
grep ich /root/lines
```
