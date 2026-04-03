# Lab 35: Process Priority and Tuned

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-35-process-priority-tuned` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning |

Tune servervm and adjust the nice level of a long-running process there.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Activate the tuned profile on servervm (servervm) - 10 pts

Install the tuned package if it is not already present and activate the tuned profile throughput-performance on servervm.

---

## Task 02 - Start the long-running sleep process on servervm (servervm) - 10 pts

Start the command sleep 3600 in the background on servervm and save its PID in /root/sleep35.pid.

---

## Task 03 - Renice the process to 5 (clientvm) - 10 pts

Adjust the nice value of that process so it becomes 5.
