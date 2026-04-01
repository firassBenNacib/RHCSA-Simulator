# Lab 21: Run A Container

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-21-run-container` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | containers |

Run a container from a prepared local image with bind mounts.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - run a container named mycontainer21 from…
**System:** clientvm

#### Command Flow
```bash
id runner21 || useradd -m runner21
passwd runner21
# enter: cinder9
su - runner21
podman run -d --name mycontainer21 -v /opt/file21:/data/input:Z -v /opt/processed21:/data/output:Z localhost/text2pdf21:latest
podman ps
exit
```

---

### Task 02 - Bind mount /opt/file21 to /data/input and…
**System:** clientvm

#### Command Flow
```bash
# No commands provided.
```

---

### Verification
```bash
runuser -l runner21 -c "podman ps --format "{{.Names}}""
```
