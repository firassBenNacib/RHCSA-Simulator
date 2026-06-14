# RHCSA 10 Lab 24: Process Priority

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-24-process-priority` |
| Mode | Lab |
| Scope | server |
| Time limit | 20 minutes |
| Objectives | processes-logs-tuning |

Identify and adjust process scheduling.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Start a detached background sleep process and save its PID in (server) - 10 pts

```bash
nohup sleep 3600 >/dev/null 2>&1 & echo $! > /run/rhcsa10-sleep.pid
cat /run/rhcsa10-sleep.pid
```

---

## Task 02 - Change the process nice value to 8 (server) - 10 pts

```bash
renice -n 8 -p $(cat /run/rhcsa10-sleep.pid)
ps -o pid,ni,comm -p $(cat /run/rhcsa10-sleep.pid)
```
