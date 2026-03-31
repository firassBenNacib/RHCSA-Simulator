# Lab 31: Shell Loop Script - Lab Solution
Scenario ID: lab-31-shell-loop-script
Mode: Lab
Time limit: 25 minutes
Objectives: shell-scripting

Create a simple shell script that uses a loop to filter files by name.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
vim /usr/local/bin/listlogs31
#!/bin/bash
for item in /opt/lab31/*; do
    if [[ "$item" == *.log ]]; then
        echo "$item" >> /root/listlogs31.out
    fi
done
chmod +x /usr/local/bin/listlogs31
```

## Task 02 - Part 02 (clientvm)
```bash
/usr/local/bin/listlogs31
```

Verification
```bash
cat /root/listlogs31.out
```
