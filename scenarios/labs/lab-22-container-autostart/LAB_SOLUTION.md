# Lab 22: Container Autostart With Systemd

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-22-container-autostart` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | containers |

Run a rootless container as a persistent user service.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure merin22 exists and run the container (clientvm) - 10 pts

```bash
useradd -m merin22
passwd merin22
# enter: cinder9
su - merin22
podman run -d --name render22 -v /opt/inbox22:/data/input:Z -v /opt/outbox22:/data/output:Z localhost/fluxpdf22:latest
```

---

## Task 02 - Generate User Service (clientvm) - 10 pts

```bash
su - merin22
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user && podman generate systemd --name render22 --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-render22.service
```

---

## Task 03 - Enable Lingering (clientvm) - 10 pts

```bash
loginctl enable-linger merin22
su - merin22
systemctl --user status container-render22.service --no-pager
```
