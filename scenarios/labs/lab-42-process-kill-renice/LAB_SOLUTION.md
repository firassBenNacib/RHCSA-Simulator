# Lab 42: Process Kill And Renice

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-42-process-kill-renice` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | systemd-and-processes |

Identify a running process, terminate it, and adjust the scheduling priority of another one.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - user worker42 has a CPU-bound process whose PID is…
**System:** clientvm

#### Command Flow
```bash
kill "$(cat /home/worker42/cpu.pid)"
```

---

### Task 02 - User worker42 also has a long-running sleep process…
**System:** clientvm

#### Command Flow
```bash
renice 10 -p "$(cat /home/worker42/sleep.pid)"
```

---

### Verification
```bash
[ ! -d "/proc/$(cat /home/worker42/cpu.pid)" ]
ps -o ni= -p "$(cat /home/worker42/sleep.pid)"
```
