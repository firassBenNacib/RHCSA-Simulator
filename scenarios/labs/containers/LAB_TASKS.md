# Container Image And Runtime Management - Lab Tasks
Scenario ID: containers
Mode: Lab
Time limit: 75 minutes
Objectives: containers

Practice RHCSA v9 image inspection, podman, skopeo, Containerfile work, bind mounts, and container systemd unit generation.

## Task 01 - Base Image Inspection (clientvm) - 15 pts
Inspect localhost/rhcsa-httpd-base:latest and save the inspection output to /root/rhcsa-httpd-base.inspect.json, loading /opt/rhcsa/container-assets/rhcsa-httpd-base.tar first if the image is missing.

## Task 02 - Container Build (clientvm) - 15 pts
Create a Containerfile under /opt/rhcsa/workspaces/container that builds an image named localhost/rhcsa-web:latest.

## Task 03 - Running Web Container (clientvm) - 15 pts
Run a container named rhcsa-web publishing host port 8080 to the container service port and bind-mount /opt/rhcsa/workspaces/container/site-content into the container with the correct SELinux handling.

## Task 04 - Container Systemd Unit (clientvm) - 15 pts
Generate a systemd unit for the container so it can be managed persistently.

Hints
1. Use podman images first to see what is already available.
2. Use podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar if the base image is not already present.
3. The bind mount should use SELinux-aware options.

Checks
```bash
test -s /root/rhcsa-httpd-base.inspect.json
podman images
podman ps --all
curl http://localhost:8080/
ls ~/.config/systemd/user | grep rhcsa-web
```
