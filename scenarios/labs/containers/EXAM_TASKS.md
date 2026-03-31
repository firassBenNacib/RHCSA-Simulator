# Container Image And Runtime Management - Exam Tasks
Scenario ID: containers
Mode: Exam
Time limit: 75 minutes
Objectives: containers

Practice RHCSA v9 image inspection, podman, skopeo, Containerfile work, bind mounts, and container systemd unit generation.

## Task 01 - Base Image Inspection (clientvm) - 15 pts
Inspect localhost/rhcsa-httpd-base:latest and write the inspection output to /root/rhcsa-httpd-base.inspect.json, loading /opt/rhcsa/container-assets/rhcsa-httpd-base.tar first if needed.

## Task 02 - Container Build (clientvm) - 15 pts
Use localhost/rhcsa-httpd-base:latest to build localhost/rhcsa-web:latest from /opt/rhcsa/workspaces/container/Containerfile.

## Task 03 - Running Web Container (clientvm) - 15 pts
Run the rhcsa-web container on host port 8080 with the provided site-content bind mount.

## Task 04 - Container Systemd Unit (clientvm) - 15 pts
Generate a systemd unit so the container can be managed persistently.
