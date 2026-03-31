# Lab 29: Firewalld Rich Rule - Lab Tasks
Scenario ID: lab-29-firewalld-rich-rule
Mode: Lab
Time limit: 20 minutes
Objectives: networking-and-firewall

Use a persistent rich rule to restrict access to a custom port by source network.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Configure a persistent firewalld rich rule that allows TCP port 2222 only from the source network 192.168.122.0/24.

## Task 02 - Part 02 (clientvm)
Reload firewalld and verify that the rule is active.

Hints
1. Use firewall-cmd --permanent --add-rich-rule.
2. List the effective rich rules after reloading.

Checks
```bash
firewall-cmd --list-rich-rules
```
