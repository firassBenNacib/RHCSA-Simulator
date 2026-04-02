# Lab 31: Shell Loop Script

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-31-shell-loop-script` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | shell-scripting |

Create a simple shell script that uses a loop to filter files by name.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create an executable script (clientvm) - 10 pts

Create an executable script /usr/local/bin/listlogs31 that loops over the files in /opt/lab31 and writes the absolute path of each file ending in .log to /root/listlogs31.out.

---

## Task 02 - Run the script once (clientvm) - 10 pts

Run the script once.

## Hints
- A for loop is sufficient for this task.
- Write one path per line.

## Validation Commands
```bash
diff -u <(find /opt/lab31 -maxdepth 1 -type f -name '*.log' | sort) <(sort /root/listlogs31.out)
```
