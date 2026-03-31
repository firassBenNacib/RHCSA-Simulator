# Scheduling, Services, And Time Sync - Exam Tasks
Scenario ID: software-scheduling-time
Mode: Exam
Time limit: 75 minutes
Objectives: software-scheduling-time

Practice RHCSA v9 time synchronization, service control, cron, at, and persistent service enablement.

## Task 01 - Chrony Client (clientvm) - 10 pts
Configure chrony to synchronize against servervm and enable the service.

## Task 02 - Schedule Note Service (clientvm) - 10 pts
Enable and start schedule-note.service so it writes /var/tmp/schedule-note.txt.

## Task 03 - Local Schedule Page (clientvm) - 10 pts
Enable and start httpd and make /var/www/html/schedule/index.html available locally.

## Task 04 - Root Cron Job (clientvm) - 10 pts
Schedule a root cron job to append the date hourly to /var/log/rhcsa-cron.log.

## Task 05 - One-Time At Job (clientvm) - 10 pts
Schedule a one-time at job that writes RHCSA to /root/at-job.txt.
