# Mock Exam C: NorthStar Recovery Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, selinux-and-default-perms, storage-lvm, containers |

A third 22 task RHCSA style mock exam with another variable set and recovery workflow.

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

## Question 01 - Root Recovery (clientvm) - 5 pts

Recover root access on clientvm from the console.

- **Set the root password to:** cinder9

---

## Question 02 - Client Network (clientvm) - 5 pts

Configure networking on clientvm with the following settings:

- **IP Address:** 192.168.122.28
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.northstar.lab

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

Configure the bootloader on clientvm so that every installed kernel boots with the kernel argument audit_backlog_limit=8192.

**Requirements**
- The change must persist across reboots.
- Do not rely on a one-time edit at the GRUB menu.

---

## Question 04 - Client Repositories (clientvm) - 5 pts

Configure a repository file on clientvm with the following settings:

- **BaseOS:** http://servervm/repo/BaseOS/
- **AppStream:** http://servervm/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 05 - Server Repositories (servervm) - 5 pts

Configure the same repository file on servervm.

- **BaseOS:** http://servervm/repo/BaseOS/
- **AppStream:** http://servervm/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 06 - Apache Firewall SELinux (clientvm) - 5 pts

Configure the Apache HTTP server on clientvm so that it serves the existing site on TCP port 8484.

**Requirements**
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Allow the port in SELinux.
- Do not alter the existing site content.

---

## Question 07 - Users And Group (clientvm) - 5 pts

Create group infrac and users talia and ren with infrac as a supplementary group. Create user sage with /sbin/nologin and no infrac membership.

---

## Question 08 - User Passwords (clientvm) - 5 pts

Set the password of talia, ren, and sage to cinder9.

---

## Question 09 - Delegated Sudo (clientvm) - 5 pts

Allow members of infrac to run useradd with sudo, and allow talia to run passwd for other users without a sudo password prompt.

---

## Question 10 - Setgid Directory (clientvm) - 5 pts

Create /srv/infrac with group ownership infrac, mode 2770, and inherited group ownership for new files.

---

## Question 11 - Cron Logger (clientvm) - 5 pts

Configure a cron job for ren that runs every 5 minutes and logs the message "NorthStar exam".

---

## Question 12 - Chrony Client (clientvm) - 5 pts

Configure chrony on clientvm so it synchronizes only with servervm.

---

## Question 13 - Autofs Map (clientvm) - 4 pts

Create user remote63 with password cinder9 and configure autofs so that the following mount becomes available on demand:

- **Local Path:** /bluec/remote63
- **Remote Export:** servervm:/exports/bluec

---

## Question 14 - Fixed UID User (clientvm) - 4 pts

Create user kian431 with UID 4431 and set its password to cinder9.

---

## Question 15 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-c/find that are owned by ren and were modified in the last 24 hours, then copy them to /root/ren-files while preserving the directory structure.

---

## Question 16 - Grep Filter (clientvm) - 4 pts

Extract lines containing orbit from /usr/share/dict/words into /root/orbit-lines.

---

## Question 17 - Archive (clientvm) - 4 pts

Create /root/etc-c.tar.bz2 containing /etc.

---

## Question 18 - Service Status Script (clientvm) - 4 pts

Create executable script /usr/local/bin/northcheck that writes the active state of each service listed in /usr/local/share/exam-c/check.lst to /root/north-services.txt.

---

## Question 19 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 700 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 20 - Resize Existing LV (clientvm) - 4 pts

Resize /dev/reviewvgc/reviewc so the final size is 340 MiB without losing data.

---

## Question 21 - Rootless Container (clientvm) - 4 pts

As user eirac, build localhost/northstar-web:latest from /opt/rhcsa/workspaces/exam-c/Containerfile, then run container pdfc with /opt/inc mounted to /data/input and /opt/outc mounted to /data/output.

---

## Question 22 - Container Autostart (clientvm) - 4 pts

Generate and enable a systemd user service for pdfc and enable lingering for eirac.
