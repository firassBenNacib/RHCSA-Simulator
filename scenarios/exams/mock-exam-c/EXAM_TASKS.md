# Mock Exam C: NorthStar Recovery Review

## Exam Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, selinux-and-default-perms, storage-lvm, containers |

A third 22 task RHCSA style mock exam with another variable set and recovery workflow.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use the exact scenario variables shown in each question.
3. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 — Root Recovery
**System:** clientvm

Recover root access on clientvm from the console.

Set the root password to: redhat

---

## Question 02 — Client Network
**System:** clientvm

Configure networking on clientvm with the following settings:

IP ADDRESS: 192.168.122.28
NETMASK: 255.255.255.0
GATEWAY: 192.168.122.1
DNS SERVER: 192.168.122.3
HOSTNAME: clientvm.northstar.lab

---

## Question 03 — Bootloader Kernel Argument
**System:** clientvm

Configure the bootloader on clientvm so that every installed kernel boots with the kernel argument audit=1.

Requirements:
- The change must persist across reboots.
- Do not rely on a one-time edit at the GRUB menu.

---

## Question 04 — Client Repositories
**System:** clientvm

Configure a repository file on clientvm with the following settings:

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

---

## Question 05 — Server Repositories
**System:** servervm

Configure the same repository file on servervm.

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

---

## Question 06 — Apache Firewall SELinux
**System:** clientvm

Configure the Apache HTTP server on clientvm so that it serves the existing site on TCP port 8484.

Requirements:
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Allow the port in SELinux.
- Do not alter the existing site content.

---

## Question 07 — Users And Group
**System:** clientvm

Create group infrac and users talia and ren with infrac as a supplementary group. Create user sage with /sbin/nologin and no infrac membership.

---

## Question 08 — User Passwords
**System:** clientvm

Set the password of talia, ren, and sage to redhat.

---

## Question 09 — Delegated Sudo
**System:** clientvm

Allow members of infrac to run useradd with sudo, and allow talia to run passwd for other users without a sudo password prompt.

---

## Question 10 — Setgid Directory
**System:** clientvm

Create /srv/infrac with group ownership infrac, mode 2770, and inherited group ownership for new files.

---

## Question 11 — Cron Logger
**System:** clientvm

Configure a cron job for ren that runs every 5 minutes and logs the message "NorthStar exam".

---

## Question 12 — Chrony Client
**System:** clientvm

Configure chrony on clientvm so it synchronizes only with servervm.

---

## Question 13 — Autofs Map
**System:** clientvm

Create user remote63 with password redhat and configure autofs so that the following mount becomes available on demand:

LOCAL PATH: /bluec/remote63
REMOTE EXPORT: servervm:/exports/bluec

---

## Question 14 — Fixed UID User
**System:** clientvm

Create user kian431 with UID 4431 and set its password to redhat.

---

## Question 15 — Find And Copy
**System:** clientvm

Find all files under /opt/exam-c/find that are owned by ren and were modified in the last 24 hours, then copy them to /root/ren-files while preserving the directory structure.

---

## Question 16 — Grep Filter
**System:** clientvm

Extract lines containing orbit from /usr/share/dict/words into /root/orbit-lines.

---

## Question 17 — Archive
**System:** clientvm

Create /root/etc-c.tar.bz2 containing /etc.

---

## Question 18 — Service Status Script
**System:** clientvm

Create executable script /usr/local/bin/northcheck that writes the active state of each service listed in /usr/local/share/exam-c/check.lst to /root/north-services.txt.

---

## Question 19 — Swap Space
**System:** clientvm

On /dev/sdb, create a 700 MiB swap partition.

Requirements:
- Enable it immediately.
- Configure it persistently.

---

## Question 20 — Resize Existing LV
**System:** clientvm

Resize /dev/reviewvgc/reviewc so the final size is 340 MiB without losing data.

---

## Question 21 — Rootless Container
**System:** clientvm

As user eirac, build localhost/northstar-web:latest from /opt/rhcsa/workspaces/exam-c/Containerfile, then run container pdfc with /opt/inc mounted to /data/input and /opt/outc mounted to /data/output.

---

## Question 22 — Container Autostart
**System:** clientvm

Generate and enable a systemd user service for pdfc and enable lingering for eirac.
