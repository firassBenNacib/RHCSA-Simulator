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

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Run The Container
**System:** clientvm

#### Command Flow
```bash
id student22 || useradd -m student22
passwd student22
# enter: redhat
runuser -l student22 -c "podman run -d --name mycontainer22 -v /opt/file22:/data/input:Z -v /opt/processed22:/data/output:Z localhost/text2pdf22:latest"
```

---

### Task 02 — Generate User Service
**System:** clientvm

#### Command Flow
```bash
runuser -l student22 -c "mkdir -p ~/.config/systemd/user"
runuser -l student22 -c "cd ~/.config/systemd/user && podman generate systemd --name mycontainer22 --files --new"
runuser -l student22 -c "systemctl --user daemon-reload"
runuser -l student22 -c "systemctl --user enable --now container-mycontainer22.service"
```

---

### Task 03 — Enable Lingering
**System:** clientvm

#### Command Flow
```bash
loginctl enable-linger student22
runuser -l student22 -c "systemctl --user status container-mycontainer22.service --no-pager"
```

---

### Verification
```bash
loginctl show-user student22 | grep Linger
runuser -l student22 -c "systemctl --user status container-mycontainer22.service --no-pager"
```
