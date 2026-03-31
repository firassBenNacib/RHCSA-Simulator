# Lab 34: Journald Persistence and Rsyslog

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-34-journald-rsyslog` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | system-services-and-targets, logging-and-processes |

Configure persistent journal storage and a custom rsyslog drop-in for authentication warnings.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

Configure journald on clientvm so logs are stored persistently across reboots.

---

## Task 02 — Part 02
**System:** clientvm

Create the drop-in file /etc/rsyslog.d/10-auth34.conf so authpriv messages with priority warning and higher are written to /var/log/auth34.log.

---

## Task 03 — Part 03
**System:** clientvm

Ensure the rsyslog service is active after your changes.

### Hints
- Persistent journald storage requires the correct directory.
- Reload or restart the affected logging services after you update their configuration.

### Checks
```bash
test -d /var/log/journal
test -f /etc/rsyslog.d/10-auth34.conf
systemctl is-active rsyslog | grep -qx active
```
