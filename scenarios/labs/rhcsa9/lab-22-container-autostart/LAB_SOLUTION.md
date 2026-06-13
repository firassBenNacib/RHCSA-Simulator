# Lab 22: Container Autostart with Systemd

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-22-container-autostart` |
| Mode | Lab |
| Scope | client |
| Time limit | 35 minutes |
| Objectives | containers |

Run a rootless container as a persistent user service.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure merin22 exists and run the container (client) - 10 pts

```bash
id merin22 >/dev/null 2>&1 || useradd -m merin22
passwd merin22
# enter: cinder9
su - merin22
podman run -d --name render22 -v /opt/inbox22:/data/input:Z -v /opt/outbox22:/data/output:Z localhost/fluxpdf22:latest
exit
```

---

## Task 02 - Enable lingering for merin22 (client) - 10 pts

```bash
loginctl enable-linger merin22
uid=$(id -u merin22)
systemctl start user@$uid.service
for i in $(seq 1 30); do [ -S /run/user/$uid/bus ] && break; sleep 1; done
```

---

## Task 03 - Generate and enable the user service (client) - 10 pts

```bash
runuser -l merin22 -c 'mkdir -p ~/.config/systemd/user'
runuser -l merin22 -c 'cd ~/.config/systemd/user && podman generate systemd --name render22 --files'
runuser -l merin22 -c 'podman kill render22 >/dev/null 2>&1 || true'
runuser -l merin22 -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus systemctl --user daemon-reload'
runuser -l merin22 -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus systemctl --user enable --now container-render22.service'
```
