# Lab 13: Text Filtering With Grep - Lab Solution
Scenario ID: lab-13-grep-filter
Mode: Lab
Time limit: 15 minutes
Objectives: essential-tools

Extract matching lines from a seeded words file.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
grep "ich" /usr/share/dict/words > /root/lines
```

Verification
```bash
grep ich /root/lines
```
