# Lab 35: Process Priority and Tuned

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-35-process-priority-tuned` |
| Mode | Lab |
| Scope | server |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning |

Tune server and adjust the nice level of a long-running process there.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Activate the tuned profile on server (server) - 10 pts

On server, install the tuned package if it is not already present and activate the tuned profile throughput-performance on server.

---

## Task 02 - Start the long-running sleep process on server (server) - 10 pts

On server, start the command sleep 3600 in the background on server and save its PID in /root/sleep35.pid.

---

## Task 03 - Renice the process to 5 (server) - 10 pts

On server, adjust the nice value of that process so it becomes 5.
