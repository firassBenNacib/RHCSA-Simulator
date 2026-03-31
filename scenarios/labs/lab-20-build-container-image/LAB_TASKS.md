# Lab 20: Build Container Image

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-20-build-container-image` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | containers |

Build and tag a local container image from a provided Containerfile.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

As user builder20, build an image named localhost/text2pdf20:latest from /opt/rhcsa/workspaces/text2pdf20/Containerfile.

---

## Task 02 — Part 02
**System:** clientvm

Verify that the image exists locally for that user.

### Hints
- The Containerfile is already present in the workspace.
- Use podman build.

### Checks
```bash
runuser -l builder20 -c "podman images"
```
