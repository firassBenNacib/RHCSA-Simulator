# Mock Exam C: Recovery And Automation - Lab Tasks
Scenario ID: mock-exam-c
Mode: Lab
Time limit: 120 minutes
Objectives: boot-and-recovery, software-scheduling-time, shell-scripting, containers

A redesigned RHCSA v9 mock exam focused on password recovery, shell scripting, scheduling, and rootless container management.

## Task 01 - Boot Recovery (clientvm) - 20 pts
Recover root access on clientvm through the bootloader recovery path, return the system to a normal boot state, and leave Vagrant SSH access working again after the reboot.

## Task 02 - One-Time At Job (clientvm) - 15 pts
Enable atd and schedule a one-time job that writes automation window ready to /root/automation-at.txt.

## Task 03 - Service Audit Script (clientvm) - 20 pts
Create an executable script /usr/local/bin/service-audit that reads /opt/rhcsa/workspaces/automation/services.lst and writes /root/service-audit.txt with one line per service in the format service_name:state where state is active, inactive, or missing. Run it successfully.

## Task 04 - Root Cron Automation (clientvm) - 15 pts
Schedule root cron to run /usr/local/bin/service-audit hourly at minute 12 and append the output to /var/log/service-audit.log.

## Task 05 - Rootless Container Service (clientvm) - 30 pts
As user admin, load /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into the rootless image store if localhost/rhcsa-httpd-base:latest is missing, build a rootless image named localhost/briefing-web:latest from /opt/rhcsa/workspaces/automation-container/Containerfile, run container briefing-web on host port 8090 with the provided site-content bind mount using correct SELinux handling, generate a user systemd unit, and configure it to start automatically after reboot.

Hints
1. Complete the recovery first so normal host-side SSH returns before you finish the automation tasks.
2. at is already installed in the clean baseline; you only need to enable atd and submit the job.
3. The shell script should use a loop and a conditional branch so missing services are reported cleanly.
4. For the rootless container task, load the local base image as admin first if it is not already present, and remember both the user service and user lingering requirement.

Checks
```bash
vagrant ssh clientvm
systemctl status atd --no-pager
cat /root/service-audit.txt
crontab -l
runuser -l admin -c 'podman ps --all'
runuser -l admin -c 'systemctl --user status container-briefing-web.service --no-pager'
curl http://localhost:8090/
```
