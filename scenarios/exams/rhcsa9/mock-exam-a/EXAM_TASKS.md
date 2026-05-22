# Mock Exam A

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-a` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam focused on recovery, repositories, Apache, sudo delegation, storage, and rootless containers.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (client) - 5 pts

Recover root access on client from the console.

Set the root password to: cinder9

---

## Question 02 - Client Network (client) - 5 pts

Configure networking on client with the following settings:

- **IP Address:** 192.168.122.26
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** client.exam-a.lab

---

## Question 03 - Bootloader Kernel Argument (client) - 5 pts

Configure the bootloader on client so every installed kernel boots with the kernel argument audit_backlog_limit=8192.

**Requirements**
- The change must persist across reboots.
- Do not rely on a one-time GRUB edit.

---

## Question 04 - Client Repositories (client) - 5 pts

Configure a repository file on client with the following settings:

- **BaseOS:** http://server/repo/BaseOS/
- **AppStream:** http://server/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 05 - Server Repositories (server) - 5 pts

Configure the same repository file on server.

- **BaseOS:** http://server/repo/BaseOS/
- **AppStream:** http://server/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 06 - Apache SELinux Port (client) - 5 pts

Configure Apache on client so it serves the existing site on TCP port 8282.

**Requirements**
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Make the SELinux change required for the new port.
- Leave the existing document root content in place.

---

## Question 07 - Users And Group (client) - 5 pts

Create group sysopsa and ensure users violet and amber have sysopsa as a supplementary group. Create user frost without a home directory and with login shell /sbin/nologin.

---

## Question 08 - User Passwords (client) - 5 pts

Set the password of violet, amber, and frost to cinder9.

---

## Question 09 - Delegated Sudo (client) - 5 pts

Allow members of sysopsa to run /usr/sbin/useradd through sudo. Allow violet to run /usr/bin/passwd for other users without a sudo password prompt. Use sudoers drop-ins.

---

## Question 10 - Setgid Directory (client) - 5 pts

Create /srv/sysopsa owned by root:sysopsa with mode 2770 so new files inherit the sysopsa group.

---

## Question 11 - Cron Logger (client) - 5 pts

Configure a cron job for amber that runs every 2 minutes and logs the message "exam-a tick".

---

## Question 12 - Host Entry (client) - 5 pts

Add a persistent hosts entry on client so api.exam-a.lab resolves to 192.168.122.3.

---

## Question 13 - Fixed UID User (client) - 4 pts

Create user ash420 with UID 4420 and set its password to cinder9.

---

## Question 14 - Find And Copy (client) - 4 pts

Find all files under /opt/exam-a/find that are owned by amber and were modified within the last 24 hours. Copy them to /root/amber-files while preserving the source directory structure.

---

## Question 15 - Grep Filter (client) - 4 pts

Extract lines containing delta from /usr/share/dict/words into /root/delta-lines.

---

## Question 16 - Archive (client) - 4 pts

Create /root/etc-opsa.tar.bz2 containing /etc.

---

## Question 17 - Service Report Script (client) - 4 pts

Create executable script /usr/local/bin/opsa-report that writes the active state of each service listed in /usr/local/share/exam-a/services.lst to /root/opsa-services.txt.

---

## Question 18 - Swap Space (client) - 4 pts

On /dev/sdb, create a 700 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 19 - Resize Existing LV (client) - 4 pts

Resize /dev/reviewvga/reviewa so the final size is 320 MiB without losing data.

---

## Question 20 - Rootless Container (client) - 4 pts

As user oriona, build localhost/opsa-web:latest from /opt/rhcsa/workspaces/exam-a/Containerfile, then run container pdfa with /opt/inc mounted to /data/input and /opt/outa mounted to /data/output.

---

## Question 21 - Container Autostart (client) - 4 pts

Generate and enable a systemd user service for pdfa and enable lingering for oriona.

---

## Question 22 - Persistent Journal (server) - 4 pts

On server, enable persistent systemd journal storage and restart systemd-journald.
