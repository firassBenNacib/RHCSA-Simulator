# RHCSA 10 Lab 31: Systemd Timer

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `rhcsa10-lab-31-systemd-timer` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Create and enable a persistent systemd timer.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /usr/local/sbin/rhcsa10-timer.sh so it appends TIMER OK to /var/l (client) - 10 pts

```bash
cat > /usr/local/sbin/rhcsa10-timer.sh <<'EOF'
#!/bin/bash
echo TIMER OK >> /var/log/rhcsa10-timer.log
EOF
chmod +x /usr/local/sbin/rhcsa10-timer.sh
```

---

## Task 02 - Create a oneshot service named rhcsa10-timer.service that runs /usr/loca (client) - 10 pts

```bash
cat > /etc/systemd/system/rhcsa10-timer.service <<'EOF'
[Unit]
Description=rhcsa10-timer service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/rhcsa10-timer.sh
EOF
```

---

## Task 03 - Create rhcsa10-timer.timer so it runs every 5 minutes, is persistent, an (client) - 10 pts

```bash
cat > /etc/systemd/system/rhcsa10-timer.timer <<'EOF'
[Unit]
Description=Run rhcsa10-timer

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now rhcsa10-timer.timer
```
