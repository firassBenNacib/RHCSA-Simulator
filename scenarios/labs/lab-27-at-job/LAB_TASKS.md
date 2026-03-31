# Lab 27: At Job Scheduling

## Lab Tasks
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

Create the user atuser27 and set its password to redhat.

---

## Task 02 — Part 02
**System:** clientvm

Enable and start the atd service.

---

## Task 03 — Part 03
**System:** clientvm

As user atuser27, schedule a one-time at job that appends the text AT27 OK to /home/atuser27/at27.log two minutes from now.

### Hints
- You can submit the job to at with standard input.
- Use atq to verify that the job is queued.

### Checks
```bash
systemctl is-enabled atd
systemctl is-active atd
atq
```
