# Mock Exam H

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-h` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, software-management, users-sudo-ssh, processes-logs-tuning, storage-lvm, containers |

A 22-task RHCSA practice mock exam covering repositories, SELinux HTTP changes, chrony, package work, and container inspection.

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

- **IP Address:** 192.168.122.40
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** client.exam-h.lab

---

## Question 02 - Host Entry (client) - 5 pts

On client, add a persistent hosts entry so registry.exam-h.lab resolves to 192.168.122.3.

---

## Question 03 - Client Repositories (client) - 5 pts

On client, configure a repository file on client with BaseOS and AppStream served from server, enabled, and with gpgcheck disabled.

---

## Question 04 - Server Repositories (server) - 5 pts

On server, configure the same repository file on server.

---

## Question 05 - Apache SELinux Port (client) - 5 pts

On client, configure Apache on client so it serves the existing site on TCP port 8181.

**Requirements**
- Start automatically at boot.
- Open the port permanently in the firewall.
- Apply the SELinux change required for the new port.

---

## Question 06 - Pwquality Policy (client) - 5 pts

On client, configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 07 - No-Home User (client) - 5 pts

On client, create user agingh without a home directory, with shell /sbin/nologin, and set its password to cinder9.

---

## Question 08 - Per-User Password Aging (client) - 5 pts

On client, set password aging for agingh to minimum 2 days, maximum 30 days, warning 7 days, and force a password change at the next login.

---

## Question 09 - Sticky Directory (client) - 5 pts

On client, create /srv/silver-drop as a sticky directory with ownership root:root and mode 1777.

---

## Question 10 - Chrony Server (server) - 5 pts

On server, configure chronyd on server so it serves time to 192.168.122.0/24 and starts automatically at boot.

---

## Question 11 - Chrony Client (client) - 5 pts

On client, configure chronyd on client so it synchronizes only with server and starts automatically at boot.

---

## Question 12 - Firewalld Rich Rule (client) - 5 pts

On client, add a permanent rich firewall rule allowing TCP port 2222 only from 192.168.122.0/24.

---

## Question 13 - Useradd Defaults (client) - 4 pts

On client, set the default inactive period for newly created local users to 10 days.

---

## Question 14 - Find and Copy (client) - 4 pts

On client, find all files under /opt/exam-h/find that are owned by watcherh and were modified within the last 24 hours, then copy them to /root/watcherh-files while preserving the source directory structure.

---

## Question 15 - Grep Filter (client) - 4 pts

On client, extract lines containing silver from /usr/share/dict/words into /root/silver-lines.

---

## Question 16 - Archive (client) - 4 pts

On client, create /root/usr-local-h.tar.gz containing /usr/local.

---

## Question 17 - Swap Space (client) - 4 pts

On client, on /dev/sdb, create a 672 MiB swap partition and configure it persistently.

---

## Question 18 - Resize Existing LV (client) - 4 pts

On client, resize /dev/reviewvgh/reviewh so the final size is 320 MiB without losing the existing file system or data.

---

## Question 19 - Boot Target and Services (client) - 4 pts

On client, configure client to boot into multi-user.target by default. Ensure rsyslog is enabled and running. If postfix is installed, disable it and stop it.

---

## Question 20 - Install and Remove Packages (client) - 4 pts

On client, use the prepared local repositories to install the packages tree and dos2unix on client. Remove dos2unix and leave tree installed.

---

## Question 21 - Inspect Container Image (client) - 4 pts

On client, create user inspecth with password cinder9 if it does not already exist. As that user, load /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into local storage and write the configured working directory of localhost/rhcsa-httpd-base:latest to /home/inspecth/workdir.txt.

---

## Question 22 - Recommended Tuned Profile (client) - 4 pts

On client, apply the recommended tuned profile and leave it active.
