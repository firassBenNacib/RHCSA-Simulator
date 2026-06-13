# RHCSA 10 Lab 48: Network Service Boot

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-48-service-network-boot` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 20 minutes |
| Objectives | networking-and-firewall |

Configure network services to start at boot.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create /var/www/html/rhcsa10-boot.html containing BOOT10 (server) - 10 pts

On server, create /var/www/html/rhcsa10-boot.html containing BOOT10.

---

## Task 02 - Enable httpd and allow the http service permanently in firewalld (server) - 10 pts

On server, enable httpd and allow the http service permanently in firewalld.

---

## Task 03 - Save the server web page output to /root/rhcsa10-boot-check.txt (client) - 10 pts

On client, save the server web page output to /root/rhcsa10-boot-check.txt.
