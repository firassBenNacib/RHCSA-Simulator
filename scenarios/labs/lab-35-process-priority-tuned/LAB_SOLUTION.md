# Lab 35: Process Priority and Tuned

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-35-process-priority-tuned` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning |

Tune the system with the requested profile and adjust process scheduling priority.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Install the tuned package if it is not already…
**System:** clientvm

#### Command Flow
```bash
dnf install -y tuned
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

### Task 02 - Start the command sleep 3600 in the background and…
**System:** clientvm

#### Command Flow
```bash
sleep 3600 &
echo $! > /root/sleep35.pid
```

---

### Task 03 - Adjust the nice value of that process so it becomes 5
**System:** clientvm

#### Command Flow
```bash
renice 5 -p "$(cat /root/sleep35.pid)"
```

---

### Verification
```bash
tuned-adm active | grep -q throughput-performance
test -f /root/sleep35.pid
ps -o ni= -p "$(cat /root/sleep35.pid)" | tr -d " " | grep -qx 5
```
