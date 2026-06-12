# RHCSA 10 Lab 27: Rsyslog Logger

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-27-rsyslog-logger` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | processes-logs-tuning |

Create and route log messages.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - ensure rsyslog is running (server) - 10 pts

```bash
systemctl enable --now rsyslog
```

---

## Task 02 - configure local7.* messages to log to /var/log/rhcsa10-local7.log (server) - 10 pts

```bash
echo 'local7.* /var/log/rhcsa10-local7.log' > /etc/rsyslog.d/rhcsa10.conf
systemctl restart rsyslog
```

---

## Task 03 - send a logger test message with facility local7 and verify it is written (server) - 10 pts

```bash
logger -p local7.info 'RHCSA10 local7 test'
sleep 1
grep 'RHCSA10 local7 test' /var/log/rhcsa10-local7.log
```
