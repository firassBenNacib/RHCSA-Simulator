# Lab 34: Journald Persistence and Rsyslog

## Lab Solution
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

#### Commands
```bash
mkdir -p /var/log/journal
vim /etc/systemd/journald.conf
# Set: Storage=persistent
:wq
systemctl restart systemd-journald
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
vim /etc/rsyslog.d/10-auth34.conf
authpriv.warning    /var/log/auth34.log
:wq
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
systemctl restart rsyslog
systemctl enable rsyslog
```

---

### Verification
```bash
test -d /var/log/journal
test -f /etc/rsyslog.d/10-auth34.conf
systemctl is-active rsyslog | grep -qx active
```
