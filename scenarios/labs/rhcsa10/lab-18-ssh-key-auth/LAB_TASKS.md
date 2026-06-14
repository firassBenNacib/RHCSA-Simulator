# RHCSA 10 Lab 18: SSH Key Authentication

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-18-ssh-key-auth` |
| Mode | Lab |
| Scope | client-server |
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

## Task 01 - Create user key10 and set password cinder9 (client) - 10 pts

On client, create user key10 and set password cinder9.

---

## Task 02 - Create user key10 and set password cinder9 (server) - 10 pts

On server, create user key10 and set password cinder9.

---

## Task 03 - Generate an ED25519 SSH key pair for key10 with no passphrase (client) - 10 pts

On client, generate an ED25519 SSH key pair for key10 with no passphrase.

---

## Task 04 - Configure key-based SSH authentication so key10 can log in to (client + server) - 10 pts

On client, configure key-based SSH authentication so key10 can log in to key10@server without a password prompt.
