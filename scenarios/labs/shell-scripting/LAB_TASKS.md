# Shell Scripting Basics - Lab Tasks
Scenario ID: shell-scripting
Mode: Lab
Time limit: 45 minutes
Objectives: shell-scripting

Practice RHCSA v9 shell scripting with loops, conditionals, command substitution, and executable scripts.

## Task 01 - User Creation Script (clientvm) - 15 pts
Create an executable script at /usr/local/bin/rhcsa-user-summary that reads /opt/rhcsa/workspaces/shell-scripting/users.csv and creates local users only if they do not already exist.

## Task 02 - User Summary Output (clientvm) - 10 pts
The script must create /root/user-summary.txt listing how many users were created and how many already existed.

## Task 03 - Service Check Script (clientvm) - 15 pts
Create another executable script at /usr/local/bin/rhcsa-service-check that reads services.txt and writes the active or inactive state of each listed service to /root/service-status.txt.

## Task 04 - Execute The Scripts (clientvm) - 10 pts
Run both scripts successfully and leave the output files in place.

Hints
1. A while-read loop is enough for both scripts.
2. Use id or getent to decide whether a user already exists.
3. systemctl is-active is enough for the service status script.

Checks
```bash
ls -l /usr/local/bin/rhcsa-user-summary /usr/local/bin/rhcsa-service-check
cat /root/user-summary.txt
cat /root/service-status.txt
getent passwd training1 training2 training3
```
