# Lab 20: Build Container Image - Lab Tasks
Scenario ID: lab-20-build-container-image
Mode: Lab
Time limit: 30 minutes
Objectives: containers

Build and tag a local container image from a provided Containerfile.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
As user builder20, build an image named localhost/text2pdf20:latest from /opt/rhcsa/workspaces/text2pdf20/Containerfile.

## Task 02 - Part 02 (clientvm)
Verify that the image exists locally for that user.

Hints
1. The Containerfile is already present in the workspace.
2. Use podman build.

Checks
```bash
runuser -l builder20 -c "podman images"
```
