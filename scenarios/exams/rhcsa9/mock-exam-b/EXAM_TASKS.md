# Mock Exam B

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22-task RHCSA practice mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (client) - 5 pts

On client, configure networking on client with the following settings:

- **IP Address:** 192.168.122.27
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** client.exam-b.lab

---

## Question 02 - Host Entry (client) - 5 pts

On client, add a persistent hosts entry so registry.exam-b.lab resolves to 192.168.122.3.

---

## Question 03 - Chrony Server (server) - 5 pts

On server, configure chronyd on server so it serves time to 192.168.122.0/24 and starts automatically at boot.

---

## Question 04 - Chrony Client (client) - 5 pts

On client, configure chronyd on client so it synchronizes only with server and starts automatically at boot.

---

## Question 05 - Useradd Defaults (client) - 5 pts

On client, set the default inactive period for newly created local users to 20 days.

---

## Question 06 - No-Home UID User (client) - 5 pts

On client, create user cato421 with UID 4421, no home directory, and password cinder9.

---

## Question 07 - Login User with Password Aging (client) - 5 pts

On client, create user jonas with a home directory, password cinder9, and password aging of maximum 45 days, minimum 5 days, warning 7 days.

---

## Question 08 - Pwquality Policy (client) - 5 pts

On client, configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 09 - Delegated Sudo (client) - 5 pts

On client, allow mira to restart firewalld on client through sudo without a password prompt. Use a sudoers drop-in.

---

## Question 10 - SSH Port (server) - 5 pts

On server, configure sshd to listen on TCP port 2222 and keep password and public key authentication enabled.

---

## Question 11 - Rich Rule (server) - 5 pts

On server, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.

---

## Question 12 - SSH Key Generation (client) - 5 pts

On client, create user mira with a home directory and password cinder9, then as mira on client, generate an ED25519 SSH key pair with no passphrase.

---

## Question 13 - Passwordless SSH (client + server) - 4 pts

On server, create user meshremote with password cinder9 if it does not already exist. Then install mira's public key for meshremote and verify passwordless SSH access on port 2222.

---

## Question 14 - Rsync Transfer (client + server) - 4 pts

On client, use rsync over SSH port 2222 to copy /opt/exam-b/report.txt to /home/meshremote/inbox/report.txt on server.

---

## Question 15 - User Umask (client) - 4 pts

On client, set a personal umask of 027 for mira.

---

## Question 16 - Find and Copy (client) - 4 pts

On client, find all files under /opt/exam-b/find that are owned by mira and were modified within the last 24 hours. Copy them to /root/mira-files while preserving the source directory structure.

---

## Question 17 - Grep Filter (client) - 4 pts

On client, extract lines containing proto from /usr/share/dict/words into /root/proto-lines.

---

## Question 18 - Archive (client) - 4 pts

On client, create /root/usr-local-b.tar.bz2 containing /usr/local.

---

## Question 19 - Shell Script (client) - 4 pts

On client, create executable script /usr/local/bin/corecheck that writes the active state of each unit listed in /usr/local/share/exam-b/units.lst to /root/coremesh-units.txt.

---

## Question 20 - Swap Space (client) - 4 pts

On client, on /dev/sdb, create a 600 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 21 - Create and Mount LV (client) - 4 pts

On client, on /dev/sdc, create a volume group reviewvgb with a physical extent size of 8 MiB and a logical volume reviewb of 50 extents. Format it with ext4 and mount it persistently on /mnt/reviewb.

---

## Question 22 - Recommended Tuned Profile (client) - 4 pts

On client, apply the recommended tuned profile and leave it active.
