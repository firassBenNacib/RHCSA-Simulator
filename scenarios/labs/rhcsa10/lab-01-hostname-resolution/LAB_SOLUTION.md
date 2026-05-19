# RHCSA 10 Lab 01: Hostname Resolution

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-01-hostname-resolution` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | networking-and-firewall |

Configure persistent hostname and local name resolution.

### Systems
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - set the persistent hostname to client10.lab.example (client) - 10 pts

```bash
hostnamectl set-hostname client10.lab.example
```

---

## Task 02 - add a persistent hosts entry mapping server10.lab.example to 192.168.122 (client) - 20 pts

```bash
echo '192.168.122.3 server10.lab.example' >> /etc/hosts
hostnamectl --static
getent hosts server10.lab.example
```
