# Lab 21: Run A Container - Lab Tasks
Scenario ID: lab-21-run-container
Mode: Lab
Time limit: 25 minutes
Objectives: containers

Run a container from a prepared local image with bind mounts.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
As user runner21, run a container named mycontainer21 from localhost/text2pdf21:latest.

## Task 02 - Part 02 (clientvm)
Bind mount /opt/file21 to /data/input and /opt/processed21 to /data/output.

Hints
1. The local image for this lab is prebuilt.
2. Use podman run with two bind mounts.

Checks
```bash
runuser -l runner21 -c "podman ps --format "{{.Names}}""
```
