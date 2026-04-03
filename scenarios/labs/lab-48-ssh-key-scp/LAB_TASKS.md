# Lab 48: SSH Key Authentication And SCP

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-48-ssh-key-scp` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Use a key pair and scp between the two lab hosts.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create bridge48 on both systems (clientvm) - 10 pts

Create user bridge48 on both clientvm and servervm. Set the password on both systems to cinder9.

---

## Task 02 - Generate the ED25519 key pair (clientvm) - 10 pts

As user bridge48 on clientvm, generate an ED25519 SSH key pair with no passphrase.

---

## Task 03 - Enable passwordless SSH from clientvm to servervm (clientvm) - 10 pts

Configure passwordless SSH access for bridge48 from clientvm to servervm using the public key.

---

## Task 04 - Copy the payload with scp (servervm) - 10 pts

Using scp over SSH, copy /home/bridge48/payload.txt from clientvm to /home/bridge48/inbox/ on servervm.
