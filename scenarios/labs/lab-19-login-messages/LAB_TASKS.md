# Lab 19: Login Greeting Messages

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-19-login-messages` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Configure both a user-specific and a global login greeting with clearer host distribution.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the per-user greeting on server (server) - 15 pts

On server, configure a login message for user orien19 that says: Welcome to you, user Orien, you are amazing!

---

## Task 02 - Create the global login greeting on both systems (client) - 15 pts

Configure a global login message on both client and server so any user receives: Welcome [username], you are logged in! with the actual login name.
