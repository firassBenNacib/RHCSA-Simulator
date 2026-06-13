# Lab 35: Process Priority and Tuned

## Lab Solution
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

```bash
dnf install -y tuned
systemctl enable --now tuned
tuned-adm profile throughput-performance
```

---

## Task 02 - Start the long-running sleep process on server (server) - 10 pts

```bash
nohup sleep 3600 >/dev/null 2>&1 & echo $! > /root/sleep35.pid
```

---

## Task 03 - Renice the process to 5 (server) - 10 pts

```bash
# On server
renice -n 5 -p "$(cat /root/sleep35.pid)"
```
