# Scheduling, Services, And Time Sync - Lab Tasks
Scenario ID: software-scheduling-time
Mode: Lab
Time limit: 75 minutes
Objectives: software-scheduling-time

Practice RHCSA v9 time synchronization, service control, cron, at, and persistent service enablement.

## Task 01 - Chrony Client (clientvm) - 10 pts
Configure clientvm to synchronize time with servervm using chrony and confirm the service is enabled.

## Task 02 - Schedule Note Service (clientvm) - 10 pts
Enable and start schedule-note.service so it writes /var/tmp/schedule-note.txt.

## Task 03 - Local Schedule Page (clientvm) - 10 pts
Enable and start httpd and make /var/www/html/schedule/index.html available locally.

## Task 04 - Root Cron Job (clientvm) - 10 pts
Create a recurring cron job for root that appends the date to /var/log/rhcsa-cron.log every hour.

## Task 05 - One-Time At Job (clientvm) - 10 pts
Create a one-time at job that writes RHCSA to /root/at-job.txt within the next few minutes.

Hints
1. chronyd should point only at servervm for this lab.
2. schedule-note.service is already present but disabled.
3. Use crontab or /etc/cron.d for the recurring job.
4. Use atq to confirm the at job was accepted.

Checks
```bash
chronyc sources -v
systemctl status schedule-note.service --no-pager
systemctl is-enabled httpd
curl http://localhost/schedule/index.html
crontab -l
atq
```
