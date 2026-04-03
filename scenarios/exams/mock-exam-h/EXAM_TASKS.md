# Mock Exam H: SilverPeak Service Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-h` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, software-management, users-sudo-ssh, processes-logs-tuning, storage-lvm, containers |

A 22 task RHCSA style mock exam covering repositories, SELinux HTTP changes, chrony, package work, and container inspection.

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

- **IP Address:** 192.168.122.40
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.silverpeak.lab

---

## Question 02 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so registry.silverpeak.lab resolves to 192.168.122.3.

---

## Question 03 - Client Repositories (clientvm) - 5 pts

Configure a repository file on clientvm with BaseOS and AppStream served from servervm, enabled, and with gpgcheck disabled.

---

## Question 04 - Server Repositories (servervm) - 5 pts

Configure the same repository file on servervm.

---

## Question 05 - Apache SELinux Port (clientvm) - 5 pts

Configure Apache on clientvm so it serves the existing site on TCP port 8181.

**Requirements**
- Start automatically at boot.
- Open the port permanently in the firewall.
- Apply the SELinux change required for the new port.

---

## Question 06 - Pwquality Policy (clientvm) - 5 pts

Configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 07 - No-Home User (clientvm) - 5 pts

Create user agingh without a home directory, with shell /sbin/nologin, and set its password to cinder9.

---

## Question 08 - Per-User Password Aging (clientvm) - 5 pts

Set password aging for agingh to minimum 2 days, maximum 30 days, warning 7 days, and force a password change at the next login.

---

## Question 09 - Sticky Directory (clientvm) - 5 pts

Create /srv/silver-drop as a sticky directory with ownership root:root and mode 1777.

---

## Question 10 - Chrony Server (servervm) - 5 pts

Configure chronyd on servervm so it serves time to 192.168.122.0/24 and starts automatically at boot.

---

## Question 11 - Chrony Client (clientvm) - 5 pts

Configure chronyd on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

## Question 12 - Firewalld Rich Rule (clientvm) - 5 pts

On clientvm, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.

---

## Question 13 - Useradd Defaults (clientvm) - 4 pts

Set the default inactive period for newly created local users to 10 days.

---

## Question 14 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-h/find that are owned by watcherh and were modified within the last 24 hours, then copy them to /root/watcherh-files while preserving the source directory structure.

---

## Question 15 - Grep Filter (clientvm) - 4 pts

Extract lines containing silver from /usr/share/dict/words into /root/silver-lines.

---

## Question 16 - Archive (clientvm) - 4 pts

Create /root/usr-local-h.tar.gz containing /usr/local.

---

## Question 17 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 672 MiB swap partition and configure it persistently.

---

## Question 18 - Resize Existing LV (clientvm) - 4 pts

Resize /dev/reviewvgh/reviewh so the final size is 320 MiB without losing the existing file system or data.

---

## Question 19 - Boot Target And Services (clientvm) - 4 pts

Configure clientvm to boot into multi-user.target by default. Ensure rsyslog is enabled and running. If postfix is installed, disable it and stop it.

---

## Question 20 - Install And Remove Packages (clientvm) - 4 pts

Use the prepared local repositories to install the packages tree and dos2unix on clientvm. Remove dos2unix and leave tree installed.

---

## Question 21 - Inspect Container Image (clientvm) - 4 pts

Create user inspecth with password cinder9 if it does not already exist. As that user, load /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into local storage and write the configured working directory of localhost/rhcsa-httpd-base:latest to /home/inspecth/workdir.txt.

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

Apply the recommended tuned profile and leave it active.
