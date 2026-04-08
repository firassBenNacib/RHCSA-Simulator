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
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Build the text2pdf20 image as builder20 (clientvm) - 10 pts

```bash
su - builder20
cd /opt/rhcsa/workspaces/text2pdf20
podman build -t localhost/text2pdf20:latest .
podman images
exit
```

---

## Task 02 - Confirm the image exists in builder20's store (clientvm) - 10 pts

```bash
su - builder20
podman images
```
