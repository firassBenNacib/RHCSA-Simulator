# Mock Exam B: CoreMesh Service Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22 task RHCSA style mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm) - 5 pts

Configure networking on clientvm with the following settings:

- **IP Address:** 192.168.122.27
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.coremesh.lab

---

## Question 02 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so registry.coremesh.lab resolves to 192.168.122.3.

---

## Question 03 - Chrony Server (servervm) - 5 pts

Configure chronyd on servervm so it serves time to 192.168.122.0/24 and starts automatically at boot.

---

## Question 04 - Chrony Client (clientvm) - 5 pts

Configure chronyd on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

## Question 05 - Useradd Defaults (clientvm) - 5 pts

Set the default inactive period for newly created local users to 20 days.

---

## Question 06 - No-Home UID User (clientvm) - 5 pts

Create user cato421 with UID 4421, no home directory, and password cinder9.

---

## Question 07 - Primary Login User (clientvm) - 5 pts

Create user mira with a home directory and password cinder9.

---

## Question 08 - Password Aging (clientvm) - 5 pts

Create user jonas with a home directory, password cinder9, and password aging of maximum 45 days, minimum 5 days, warning 7 days.

---

## Question 09 - Pwquality Policy (clientvm) - 5 pts

Configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 10 - Delegated Sudo (clientvm) - 5 pts

Allow mira to restart firewalld on clientvm through sudo without a password prompt. Use a sudoers drop-in.

---

## Question 11 - SSH Port (servervm) - 5 pts

On servervm, configure sshd to listen on TCP port 2222 and keep password and public key authentication enabled.

---

## Question 12 - Rich Rule (servervm) - 5 pts

On servervm, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.

---

## Question 13 - SSH Key Generation (clientvm) - 4 pts

As mira on clientvm, generate an ED25519 SSH key pair with no passphrase.

---

## Question 14 - Passwordless SSH (servervm) - 4 pts

On servervm, create user meshremote with password cinder9 if it does not already exist. Then install mira's public key for meshremote and verify passwordless SSH access on port 2222.

---

## Question 15 - Rsync Transfer (servervm) - 4 pts

Use rsync over SSH port 2222 to copy /opt/exam-b/report.txt to /home/meshremote/inbox/report.txt on servervm.

---

## Question 16 - Passwordless SSH (servervm) - 4 pts

Install mira's public key for user meshremote on servervm and verify passwordless SSH access on port 2222.

---

## Question 17 - Rsync Transfer (servervm) - 4 pts

Use rsync over SSH port 2222 to copy /home/mira/report.txt to /home/meshremote/inbox/report.txt on servervm.

---

## Question 18 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-b/find that are owned by mira and were modified in the last 24 hours, then copy them to /root/mira-files while preserving the directory structure.

---

## Question 19 - Grep Filter (clientvm) - 4 pts

Extract lines containing proto from /usr/share/dict/words into /root/proto-lines.

---

## Question 20 - Archive (clientvm) - 4 pts

Create /root/usr-local-b.tar.bz2 containing /usr/local.

---

## Question 21 - Unit Status Script (clientvm) - 4 pts

Create executable script /usr/local/bin/corecheck that writes the active state of each unit listed in /usr/local/share/exam-b/units.lst to /root/coremesh-units.txt.

---

## Question 22 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 600 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.
