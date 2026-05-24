# RHCSA 10 Lab 18: SSH Key Authentication

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-18-ssh-key-auth` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure key-based SSH authentication.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - create user key10 and set password cinder9 (client) - 10 pts

On client, create user key10 and set password cinder9.

---

## Task 02 - create /home/key10/.ssh/authorized_keys with the provided public key tex (client) - 10 pts

On client, create /home/key10/.ssh/authorized_keys with the provided public key text ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIRhcsa10keydemo rhcsa10.

---

## Task 03 - set secure ownership and permissions on the SSH directory and authorized (client) - 10 pts

On client, set secure ownership and permissions on the SSH directory and authorized_keys file.
