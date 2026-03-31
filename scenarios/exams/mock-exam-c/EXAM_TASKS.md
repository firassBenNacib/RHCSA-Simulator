# Mock Exam C: Recovery And Automation - Exam Tasks
Scenario ID: mock-exam-c
Mode: Exam
Time limit: 120 minutes
Objectives: boot-and-recovery, software-scheduling-time, shell-scripting, containers

A redesigned RHCSA v9 mock exam focused on password recovery, shell scripting, scheduling, and rootless container management.

## Task 01 - Boot Recovery (clientvm) - 20 pts
Recover root access on clientvm through the bootloader recovery path and return the system to a normal boot with host-side Vagrant SSH working again.

## Task 02 - One-Time At Job (clientvm) - 15 pts
Enable atd and schedule a one-time job that writes automation window ready to /root/automation-at.txt.

## Task 03 - Service Audit Script (clientvm) - 20 pts
Create /usr/local/bin/service-audit to read /opt/rhcsa/workspaces/automation/services.lst and write /root/service-audit.txt with lines in the format service_name:state where state is active, inactive, or missing. Run it successfully.

## Task 04 - Root Cron Automation (clientvm) - 15 pts
Schedule root cron to run /usr/local/bin/service-audit hourly at minute 12 and append the output to /var/log/service-audit.log.

## Task 05 - Rootless Container Service (clientvm) - 30 pts
As user admin, load /opt/rhcsa/container-assets/rhcsa-httpd-base.tar if localhost/rhcsa-httpd-base:latest is missing, build localhost/briefing-web:latest from /opt/rhcsa/workspaces/automation-container/Containerfile, run rootless container briefing-web on port 8090 with the provided bind mount, generate a user systemd unit, and configure it to start after reboot.
