# RHCSA 10 Lab 28: Chrony Client

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-28-chrony-client` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time, processes-logs-tuning |

Configure time synchronization.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure chrony time source (server) - 10 pts

```bash
# On server
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
allow 192.168.122.0/24
local stratum 10
logdir /var/log/chrony
EOF
systemctl enable --now chronyd
```

---

## Task 02 - Configure chrony time source (client) - 10 pts

```bash
dnf install -y chrony
```

---

## Task 03 - Configure server as the only NTP source (client) - 10 pts

```bash
sed -i '/^pool /d;/^server /d' /etc/chrony.conf
echo 'server server iburst' >> /etc/chrony.conf
```

---

## Task 04 - Configure chrony time source (client) - 10 pts

```bash
systemctl enable --now chronyd
chronyc sources || true
```
