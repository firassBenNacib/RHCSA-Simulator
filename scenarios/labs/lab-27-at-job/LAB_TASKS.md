# Lab 27: At Job Scheduling - Lab Tasks
Scenario ID: lab-27-at-job
Mode: Lab
Time limit: 20 minutes
Objectives: software-scheduling-time

Schedule a one time task with at and verify that the at daemon is enabled.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create the user atuser27 and set its password to redhat.

## Task 02 - Part 02 (clientvm)
Enable and start the atd service.

## Task 03 - Part 03 (clientvm)
As user atuser27, schedule a one-time at job that appends the text AT27 OK to /home/atuser27/at27.log two minutes from now.

Hints
1. You can submit the job to at with standard input.
2. Use atq to verify that the job is queued.

Checks
```bash
systemctl is-enabled atd
systemctl is-active atd
atq
```
