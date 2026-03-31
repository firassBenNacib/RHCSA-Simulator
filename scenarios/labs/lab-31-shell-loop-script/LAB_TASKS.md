# Lab 31: Shell Loop Script - Lab Tasks
Scenario ID: lab-31-shell-loop-script
Mode: Lab
Time limit: 25 minutes
Objectives: shell-scripting

Create a simple shell script that uses a loop to filter files by name.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Create an executable script /usr/local/bin/listlogs31 that loops over the files in /opt/lab31 and writes the absolute path of each file ending in .log to /root/listlogs31.out.

## Task 02 - Part 02 (clientvm)
Run the script once.

Hints
1. A for loop is sufficient for this task.
2. Write one path per line.

Checks
```bash
cat /root/listlogs31.out
```
