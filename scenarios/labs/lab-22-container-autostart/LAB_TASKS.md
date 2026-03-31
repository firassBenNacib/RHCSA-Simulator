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

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

As user student22, run a container named mycontainer22 from localhost/text2pdf22:latest with /opt/file22 mounted to /data/input and /opt/processed22 mounted to /data/output.

---

## Task 02 — Part 02
**System:** clientvm

Generate a systemd user unit for the container, enable it, and make it start automatically after reboot.

---

## Task 03 — Part 03
**System:** clientvm

Enable lingering for student22.

### Hints
- Use podman generate systemd --files --new or podman generate systemd --new depending on the environment.
- The user service must run without an active login session.

### Checks
```bash
loginctl show-user student22 | grep Linger
runuser -l student22 -c "systemctl --user status container-mycontainer22.service --no-pager"
```
