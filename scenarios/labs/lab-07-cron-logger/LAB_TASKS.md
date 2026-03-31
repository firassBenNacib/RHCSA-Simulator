# Lab 07: Cron Scheduling - Lab Tasks
Scenario ID: lab-07-cron-logger
Mode: Lab
Time limit: 20 minutes
Objectives: software-scheduling-time

Schedule a recurring task for a specific user.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create user natcron if it does not exist and set its password to redhat.

## Task 02 - Part 02 (clientvm)
Configure a cron job for natcron that runs every 2 minutes and logs the message "Lab 07 running" with logger.

Hints
1. Use crontab -e -u natcron.
2. Leave crond enabled and running.

Checks
```bash
crontab -l -u natcron
systemctl status crond --no-pager
```
