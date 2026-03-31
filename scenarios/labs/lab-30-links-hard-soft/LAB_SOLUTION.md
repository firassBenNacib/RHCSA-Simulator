# Lab 30: Hard And Soft Links - Lab Solution
Scenario ID: lab-30-links-hard-soft
Mode: Lab
Time limit: 15 minutes
Objectives: essential-tools

Create and verify both a hard link and a symbolic link to the same source file.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
printf 'link-test
' > /root/linksource30
```

## Task 02 - Part 02 (clientvm)
```bash
ln /root/linksource30 /root/linkhard30
ln -s /root/linksource30 /root/linksoft30
```

Verification
```bash
ls -li /root/linksource30 /root/linkhard30 /root/linksoft30
readlink -f /root/linksoft30
```
