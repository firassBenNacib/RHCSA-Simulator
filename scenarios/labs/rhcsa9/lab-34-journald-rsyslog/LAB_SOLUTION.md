# Lab 34: Journald Persistence and Rsyslog

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-34-journald-rsyslog` |
| Mode | Lab |
| Scope | client |
| Time limit | 25 minutes |
| Objectives | processes-logs-tuning, software-scheduling-time |

Configure persistent journal storage and a custom rsyslog drop-in for authentication warnings.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure journald on client so logs are stored (client) - 10 pts

```bash
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-rhcsa-persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
systemctl restart systemd-journald
journalctl --flush
```

---

## Task 02 - Create the drop-in file (client) - 10 pts

```bash
vim /etc/rsyslog.d/10-auth34.conf
authpriv.warning    /var/log/auth34.log
```

---

## Task 03 - Ensure the rsyslog service is active after your (client) - 10 pts

```bash
systemctl restart rsyslog
systemctl enable rsyslog
```
