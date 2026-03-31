# Lab 01: Networking And Hostname - Lab Tasks
Scenario ID: lab-01-networking-hostname
Mode: Lab
Time limit: 35 minutes
Objectives: networking-and-firewall

Configure persistent networking and hostname settings on clientvm in RHCSA style.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.

## Task 01 - Part 01 (clientvm)
Configure the active clientvm connection with the IPv4 address 192.168.122.25/24, gateway 192.168.122.1, DNS server 192.168.122.3, and set the persistent hostname to clientvm.netlab.local.

## Task 02 - Part 02 (clientvm)
Add a persistent host entry so repo.netlab.local resolves to 192.168.122.3.

## Task 03 - Part 03 (clientvm)
Verify that the active connection comes back with the same values after reconnecting it.

Hints
1. Use nmcli or nmtui for the network profile.
2. Use hostnamectl for the persistent hostname.

Checks
```bash
hostnamectl status
nmcli connection show --active
getent hosts repo.netlab.local
```
