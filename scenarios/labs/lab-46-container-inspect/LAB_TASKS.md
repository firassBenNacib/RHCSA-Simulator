# Lab 46: Container Load And Inspect

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-46-container-inspect` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | containers |

Load a provided container image into user storage and inspect its metadata with podman.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Create user inspect46 with password redhat if it does…
**System:** clientvm

Create user inspect46 with password redhat if it does not already exist.

---

### Task 02 — load the image archive /opt/rhcsa/container-…
**System:** clientvm

As user inspect46, load the image archive /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into local storage.

---

### Task 03 — inspect localhost/rhcsa-httpd-base:latest and write…
**System:** clientvm

As user inspect46, inspect localhost/rhcsa-httpd-base:latest and write the configured working directory to /home/inspect46/workdir.txt.

---

### Task 04 — If the image has no explicit configured user, write…
**System:** clientvm

If the image has no explicit configured user, write root to /home/inspect46/user.txt. Otherwise write the configured user value.

### Hints
- Use podman image inspect with --format.

### Validation Commands
```bash
runuser -l inspect46 -c "test -s ~/workdir.txt && test -s ~/user.txt"
```
