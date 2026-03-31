# Lab 22: Container Autostart With Systemd

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-22-container-autostart` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | containers |

Run a rootless container as a persistent user service.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
id student22 || useradd -m student22
passwd student22
# enter: redhat
su - student22
podman run -d --name mycontainer22 -v /opt/file22:/data/input:Z -v /opt/processed22:/data/output:Z localhost/text2pdf22:latest
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name mycontainer22 --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-mycontainer22.service
exit
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
loginctl enable-linger student22
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
runuser -l student22 -c "systemctl --user status container-mycontainer22.service --no-pager"
```

---

### Verification
```bash
loginctl show-user student22 | grep Linger
runuser -l student22 -c "systemctl --user status container-mycontainer22.service --no-pager"
```
