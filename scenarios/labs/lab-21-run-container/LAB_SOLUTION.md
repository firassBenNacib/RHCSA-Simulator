# Lab 21: Run A Container - Lab Solution
Scenario ID: lab-21-run-container
Mode: Lab
Time limit: 25 minutes
Objectives: containers

Run a container from a prepared local image with bind mounts.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
id runner21 || useradd -m runner21
passwd runner21
# enter: redhat
su - runner21
podman run -d --name mycontainer21 -v /opt/file21:/data/input:Z -v /opt/processed21:/data/output:Z localhost/text2pdf21:latest
podman ps
exit
```

## Task 02 - Part 02 (clientvm)
```bash
# No commands provided.
```

Verification
```bash
runuser -l runner21 -c "podman ps --format "{{.Names}}""
```
