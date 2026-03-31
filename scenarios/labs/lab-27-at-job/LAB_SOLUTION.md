# Lab 27: At Job Scheduling

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-27-at-job` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Schedule a one time task with at and verify that the at daemon is enabled.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
useradd -m atuser27
passwd atuser27
# enter: redhat
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
systemctl enable --now atd
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
runuser -l atuser27 -c "echo 'echo AT27 OK >> /home/atuser27/at27.log' | at now + 2 minutes"
atq
```

---

### Verification
```bash
systemctl is-enabled atd
systemctl is-active atd
atq
```
