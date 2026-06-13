# Lab 48: SSH Key Authentication and SCP

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-48-ssh-key-scp` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Use a key pair and scp between the two lab hosts.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Ensure bridge48 exists on both systems (client + server) - 10 pts

On client, ensure user bridge48 exists on both client and server, and set the password on both systems to cinder9.

---

## Task 02 - Generate the ED25519 key pair (client) - 10 pts

On client, as user bridge48 on client, generate an ED25519 SSH key pair with no passphrase.

---

## Task 03 - Enable passwordless SSH from client to server (client + server) - 10 pts

On client, configure passwordless SSH access for bridge48 from client to server using the public key.

---

## Task 04 - Copy the payload with scp (client + server) - 10 pts

On client, using scp over SSH, copy /home/bridge48/payload.txt from client to /home/bridge48/inbox/ on server.
