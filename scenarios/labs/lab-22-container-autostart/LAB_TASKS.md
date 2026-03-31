# Lab 22: Container Autostart With Systemd

## Lab Tasks
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

Create user student22 with password redhat if it does not already exist. Then, as that user, run a container named mycontainer22 from localhost/text2pdf22:latest with /opt/file22 mounted to /data/input and /opt/processed22 mounted to /data/output.

---

### Task 02 — Generate User Service
**System:** clientvm

As user student22, generate a systemd user unit for that container and enable it.

---

### Task 03 — Enable Lingering
**System:** clientvm

Enable lingering for student22 so the user service starts automatically after reboot.

### Hints
- Use podman generate systemd --files --new or podman generate systemd --new depending on the environment.
- The user service must run without an active login session.

### Validation Commands
```bash
loginctl show-user student22 | grep Linger
runuser -l student22 -c "systemctl --user status container-mycontainer22.service --no-pager"
```
