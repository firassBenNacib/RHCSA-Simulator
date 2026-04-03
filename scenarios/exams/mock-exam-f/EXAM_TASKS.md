# Mock Exam F: AuroraPath Access Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-f` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22 task RHCSA style mock exam centered on chrony, SSH hardening, account defaults, rsync, and storage administration.

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

- **IP Address:** 192.168.122.38
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.aurora.lab

---

## Question 02 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so db.aurora.lab resolves to 192.168.122.3.

---

## Question 03 - Chrony Server (servervm) - 5 pts

Configure chronyd on servervm so it serves time to 192.168.122.0/24 and starts automatically at boot.

---

## Question 04 - Chrony Client (clientvm) - 5 pts

Configure chronyd on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

## Question 05 - SSH Port (servervm) - 5 pts

On servervm, configure sshd to listen on TCP port 2222 and keep both password and public key authentication enabled.

---

## Question 06 - Rich Rule (servervm) - 5 pts

On servervm, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.

---

## Question 07 - Useradd Defaults (clientvm) - 5 pts

Set the default inactive period for newly created local users to 14 days.

---

## Question 08 - No-Home UID User (clientvm) - 5 pts

Create user pine560 with UID 4560, no home directory, shell /sbin/nologin, and password cinder9.

---

## Question 09 - Admin User (clientvm) - 5 pts

Create user elio with a home directory and password cinder9.

---

## Question 10 - Delegated Sudo (clientvm) - 5 pts

Allow elio to restart firewalld on clientvm through sudo without a password prompt. Use a sudoers drop-in.

---

## Question 11 - SSH Key Generation (clientvm) - 5 pts

As elio on clientvm, generate an ED25519 SSH key pair with no passphrase.

---

## Question 12 - Remote Account (servervm) - 5 pts

Create user backupf on servervm with a home directory and password cinder9. Create /home/backupf/inbox and make backupf the owner.

---

## Question 13 - Passwordless SSH (servervm) - 4 pts

Install elio's public key for backupf on servervm and verify passwordless SSH access on port 2222.

---

## Question 14 - Rsync Transfer (servervm) - 4 pts

Use rsync over SSH port 2222 as elio to copy /opt/exam-f/aurora-report.txt to /home/backupf/inbox/report.txt on servervm.

---

## Question 15 - User Umask (clientvm) - 4 pts

Set a personal umask of 027 for elio.

---

## Question 16 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-f/find that are owned by seekerf and were modified within the last 24 hours. Copy them to /root/seekerf-files while preserving the source directory structure.

---

## Question 17 - Grep Filter (clientvm) - 4 pts

Extract lines containing comet from /usr/share/dict/words into /root/comet-lines.

---

## Question 18 - Archive (clientvm) - 4 pts

Create /root/usr-local-f.tar.gz containing /usr/local.

---

## Question 19 - Shell Script (clientvm) - 4 pts

Create executable script /usr/local/bin/aurora-report that writes the active state of each unit listed in /usr/local/share/exam-f/units.lst to /root/aurora-units.txt.

---

## Question 20 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 704 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 21 - Create And Mount LV (clientvm) - 4 pts

On /dev/sdc, create a volume group auroravg with a physical extent size of 8 MiB and a logical volume auroralv of 50 extents. Format it with xfs and mount it persistently on /mnt/auroralv.

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

Apply the recommended tuned profile and leave it active.
