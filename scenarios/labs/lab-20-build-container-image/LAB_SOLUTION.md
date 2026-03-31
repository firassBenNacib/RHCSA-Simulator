# Lab 20: Build Container Image - Lab Solution
Scenario ID: lab-20-build-container-image
Mode: Lab
Time limit: 30 minutes
Objectives: containers

Build and tag a local container image from a provided Containerfile.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
id builder20 || useradd -m builder20
passwd builder20
# enter: redhat
su - builder20
cd /opt/rhcsa/workspaces/text2pdf20
podman build -t localhost/text2pdf20:latest .
podman images
exit
```

## Task 02 - Part 02 (clientvm)
```bash
runuser -l builder20 -c "podman images"
```

Verification
```bash
runuser -l builder20 -c "podman images"
```
