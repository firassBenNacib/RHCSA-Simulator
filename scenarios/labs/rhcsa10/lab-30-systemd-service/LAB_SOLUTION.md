# RHCSA 10 Lab 30: Custom Service

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-30-systemd-service` |
| Mode | Lab |
| Scope | server |
| Time limit | 25 minutes |
| Objectives | software-scheduling-time |

Create and enable a custom systemd service.

### Systems
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create service helper script (server) - 10 pts

```bash
cat > /usr/local/sbin/rhcsa10-service.sh <<'EOF'
#!/bin/bash
echo SERVICE10 > /var/tmp/rhcsa10-service.out
EOF
chmod +x /usr/local/sbin/rhcsa10-service.sh
```

---

## Task 02 - Create oneshot service (server) - 10 pts

```bash
cat > /etc/systemd/system/rhcsa10-service.service <<'EOF'
[Unit]
Description=RHCSA10 oneshot service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/rhcsa10-service.sh

[Install]
WantedBy=multi-user.target
EOF
```

---

## Task 03 - Enable and start the service (server) - 10 pts

```bash
restorecon -v /usr/local/sbin/rhcsa10-service.sh /etc/systemd/system/rhcsa10-service.service || true
systemctl daemon-reload
systemctl enable --now rhcsa10-service.service
```
