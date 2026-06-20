# Lab 39: SSH Key Authentication and Rsync

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-ssh-key-rsync` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh, essential-tools |

Configure key-based SSH access and securely transfer files between systems.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure mesh39 exists on both systems (client + server) - 10 pts

On client, ensure the user mesh39 exists on both client and server, and set the password on both systems to cinder9.

---

## Task 02 - Generate an ED25519 SSH key pair with no passphrase (client) - 10 pts

On client, as user mesh39, generate an ED25519 SSH key pair with no passphrase.

---

## Task 03 - Configure passwordless SSH access for mesh39 from (client + server) - 10 pts

On client, configure passwordless SSH access for mesh39 from client to server using public key authentication.

---

## Task 04 - Using rsync over SSH, copy the directory (client + server) - 10 pts

On client, using rsync over SSH, copy the directory /home/mesh39/client-data/ from client to /home/mesh39/server-data/ on server.
