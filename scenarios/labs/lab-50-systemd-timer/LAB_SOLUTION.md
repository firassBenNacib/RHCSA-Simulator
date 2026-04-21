# Lab 50: Systemd Timer Unit

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-50-systemd-timer` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Create and enable a persistent systemd timer for RHCSA 10 practice.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the timer script (client) - 10 pts

```bash
cat > /usr/local/sbin/rhcsa-timer10.sh <<'EOF'
#!/bin/bash
echo TIMER10 OK >> /var/log/rhcsa-timer10.log
EOF
chmod +x /usr/local/sbin/rhcsa-timer10.sh
```

---

## Task 02 - Create the oneshot service (client) - 10 pts

```bash
cat > /etc/systemd/system/rhcsa-timer10.service <<'EOF'
[Unit]
Description=RHCSA timer 10 service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/rhcsa-timer10.sh
EOF
```

---

## Task 03 - Create and enable the timer (client) - 10 pts

```bash
cat > /etc/systemd/system/rhcsa-timer10.timer <<'EOF'
[Unit]
Description=Run RHCSA timer 10 every 5 minutes

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now rhcsa-timer10.timer
```
