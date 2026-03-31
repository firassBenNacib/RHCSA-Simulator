# Lab 07: Cron Scheduling - Lab Solution
Scenario ID: lab-07-cron-logger
Mode: Lab
Time limit: 20 minutes
Objectives: software-scheduling-time

Schedule a recurring task for a specific user.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
id natcron || useradd -m natcron
passwd natcron
# enter: redhat
```

## Task 02 - Part 02 (clientvm)
```bash
crontab -e -u natcron
*/2 * * * * logger "Lab 07 running"
systemctl enable --now crond
```

Verification
```bash
crontab -l -u natcron
systemctl status crond --no-pager
```
