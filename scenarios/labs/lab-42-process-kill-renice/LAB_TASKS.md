# Lab 42: Process Kill And Renice

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-42-process-kill-renice` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning |

Identify a running process, terminate it, and adjust the scheduling priority of another one.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - user worker42 has a CPU-bound process whose PID is (clientvm) - 10 pts

On clientvm, user worker42 has a CPU-bound process whose PID is stored in /home/worker42/cpu.pid. Terminate that process.

---

## Task 02 - User worker42 also has a long-running sleep process (clientvm) - 10 pts

User worker42 also has a long-running sleep process whose PID is stored in /home/worker42/sleep.pid. Change the nice value of that process to 10.
