# Lab 34: Journald Persistence and Rsyslog

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-34-journald-rsyslog` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning, software-scheduling-time |

Configure persistent journal storage and a custom rsyslog drop-in for authentication warnings.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Configure journald on clientvm so logs are stored…
**System:** clientvm

#### Command Flow
```bash
mkdir -p /var/log/journal
vim /etc/systemd/journald.conf
# Set: Storage=persistent
:wq
systemctl restart systemd-journald
```

---

### Task 02 - Create the drop-in file /etc/rsyslog.d/10-auth34.conf…
**System:** clientvm

#### Command Flow
```bash
vim /etc/rsyslog.d/10-auth34.conf
authpriv.warning    /var/log/auth34.log
:wq
```

---

### Task 03 - Ensure the rsyslog service is active after your…
**System:** clientvm

#### Command Flow
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
