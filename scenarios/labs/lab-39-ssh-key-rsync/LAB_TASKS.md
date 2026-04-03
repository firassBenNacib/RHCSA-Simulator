# Lab 39: SSH Key Authentication and Rsync

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-39-ssh-key-rsync` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh, essential-tools |

Configure key-based SSH access and securely transfer files between systems.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the user mesh39 on both clientvm and (clientvm) - 10 pts

Create the user mesh39 on both clientvm and servervm. Set the password on both systems to cinder9.

---

## Task 02 - generate an ED25519 SSH key pair with no passphrase (clientvm) - 10 pts

As user mesh39 on clientvm, generate an ED25519 SSH key pair with no passphrase.

---

## Task 03 - Configure passwordless SSH access for mesh39 from (clientvm) - 10 pts

Configure passwordless SSH access for mesh39 from clientvm to servervm using public key authentication.

---

## Task 04 - Using rsync over SSH, copy the directory (servervm) - 10 pts

Using rsync over SSH, copy the directory /home/mesh39/client-data/ from clientvm to /home/mesh39/server-data/ on servervm.
