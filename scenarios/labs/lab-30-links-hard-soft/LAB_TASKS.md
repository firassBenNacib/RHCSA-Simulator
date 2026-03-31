# Lab 30: Hard And Soft Links

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-30-links-hard-soft` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | essential-tools |

Create and verify both a hard link and a symbolic link to the same source file.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create the file /root/linksource30 containing the…
**System:** clientvm

Create the file /root/linksource30 containing the text link-test.

---

### Task 02 — Create the hard link /root/linkhard30 and the…
**System:** clientvm

Create the hard link /root/linkhard30 and the symbolic link /root/linksoft30 to /root/linksource30.

### Hints
- Use ln for both tasks, with and without -s.

### Validation Commands
```bash
ls -li /root/linksource30 /root/linkhard30 /root/linksoft30
readlink -f /root/linksoft30
```
