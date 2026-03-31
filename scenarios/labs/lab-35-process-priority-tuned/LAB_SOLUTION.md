# Lab 35: Process Priority and Tuned

## Lab Solution
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

#### Commands
```bash
dnf install -y tuned
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
sleep 3600 &
echo $! > /root/sleep35.pid
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
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
