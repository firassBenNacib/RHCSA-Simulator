# Lab 29: Firewalld Rich Rule - Lab Solution
Scenario ID: lab-29-firewalld-rich-rule
Mode: Lab
Time limit: 20 minutes
Objectives: networking-and-firewall

Use a persistent rich rule to restrict access to a custom port by source network.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

## Task 02 - Part 02 (clientvm)
```bash
firewall-cmd --list-rich-rules
```

Verification
```bash
firewall-cmd --list-rich-rules
```
