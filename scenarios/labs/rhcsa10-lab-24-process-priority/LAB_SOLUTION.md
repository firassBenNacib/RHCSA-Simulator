# RHCSA 10 Lab 24: Process Priority

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-24-process-priority` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | processes-logs-tuning |

Identify and adjust process scheduling.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Start a background sleep process and save its PID in /run/rhcsa10-sleep (client) - 10 pts

```bash
sleep 3600 & echo $! > /run/rhcsa10-sleep.pid
```

---

## Task 02 - Change the process nice value to 8 (client) - 10 pts

```bash
renice -n 8 -p $(cat /run/rhcsa10-sleep.pid)
```

---

## Task 03 - Verify the process priority (client) - 10 pts

```bash
ps -o pid,ni,comm -p $(cat /run/rhcsa10-sleep.pid)
```
