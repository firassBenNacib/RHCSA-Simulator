# Lab 35: Process Priority and Tuned

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-35-process-priority-tuned` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | logging-and-processes, system-services-and-targets |

Tune the system with the requested profile and adjust process scheduling priority.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Install the tuned package if it is not already present and activate the tuned profile throughput-performance on clientvm.

---

## Task 02 — Part 02
**System:** clientvm

Start the command sleep 3600 in the background and save its PID in /root/sleep35.pid.

---

## Task 03 — Part 03
**System:** clientvm

Adjust the nice value of that process so it becomes 5.

### Hints
- Use a persistent tuned command.
- Use ps to verify the final nice value of the target process.

### Checks
```bash
tuned-adm active | grep -q throughput-performance
test -f /root/sleep35.pid
ps -o ni= -p "$(cat /root/sleep35.pid)" | tr -d " " | grep -qx 5
```
