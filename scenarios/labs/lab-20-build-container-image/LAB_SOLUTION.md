# Lab 20: Build Container Image

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-20-build-container-image` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | containers |

Build and tag a local container image from a provided Containerfile.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - build an image named localhost/text2pdf20:latest (clientvm) - 10 pts

```bash
useradd -m builder20
passwd builder20
# enter: cinder9
su - builder20
cd /opt/rhcsa/workspaces/text2pdf20
podman build -t localhost/text2pdf20:latest .
podman images
exit
```

---

## Task 02 - Verify that the image exists locally for that user (clientvm) - 10 pts

```bash
runuser -l builder20 -c "podman images"
```
