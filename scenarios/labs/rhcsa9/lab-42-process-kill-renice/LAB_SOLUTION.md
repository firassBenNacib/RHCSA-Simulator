# Lab 42: Process Kill and Renice

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-42-process-kill-renice` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning |

Identify a running process, terminate it, and adjust the scheduling priority of another one.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Terminate worker42's CPU-bound process (client) - 10 pts

```bash
kill "$(cat /home/worker42/cpu.pid)"
```

---

## Task 02 - Change the long-running sleep process to nice 10 (client) - 10 pts

```bash
renice 10 -p "$(cat /home/worker42/sleep.pid)"
```
