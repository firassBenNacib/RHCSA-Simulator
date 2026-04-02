# Mock Exam E: HarborGrid Recovery Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, software-scheduling-time, storage-lvm, selinux-and-default-perms |

A 22 question RHCSA style mock exam for RHEL 9 that adds pwquality, at scheduling, tuned, and an existing logical volume resize.

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

- **IP Address:** 192.168.122.37
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.harbor.lab

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

## Question 06 - Apache SELinux Port (clientvm) - 5 pts

Configure the Apache HTTP server on clientvm so that it serves the existing site on TCP port 8181.

**Requirements**
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Make the SELinux change required for the new port.
- Do not alter the existing site content.

---

## Question 07 - Users And Group (clientvm) - 5 pts

Create group harborops and users lena and ivor with harborops as a supplementary group. Create user hush with /sbin/nologin and no harborops membership.

---

## Question 08 - User Passwords (clientvm) - 5 pts

Set the password of lena, ivor, and hush to cinder9.

---

## Question 09 - Delegated Sudo (clientvm) - 5 pts

Allow members of harborops to run useradd through sudo, and allow lena to restart httpd through sudo without a password prompt.

---

## Question 10 - Setgid Directory (clientvm) - 5 pts

Create /srv/harbor with group ownership harborops, permissions 2770, and inherited group ownership for new files.

---

## Question 11 - Pwquality Policy (clientvm) - 5 pts

Configure a persistent password quality policy in /etc/security/pwquality.conf.d so that local passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 12 - At Job (clientvm) - 5 pts

Create a one-time at job as user ivor that appends the text Harbor queued to /home/ivor/at.log two minutes from now. Ensure the atd service is enabled and running.

---

## Question 13 - Chrony Client (clientvm) - 4 pts

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

## Question 14 - Autofs Map (clientvm) - 4 pts

Create user harborremote with password cinder9 and configure autofs so that the following mount becomes available on demand:

- **Local Path:** /harbor/home/harborremote
- **Remote Export:** servervm:/exports/harborhome

---

## Question 15 - Fixed UID User (clientvm) - 4 pts

Create user maple551 with UID 4551 and set its password to cinder9.

---

## Question 16 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-e/find that are owned by scoutte and were modified within the last 24 hours. Copy them to /root/scoutte-files while preserving the source directory structure.

---

## Question 17 - Grep Filter (clientvm) - 4 pts

Extract lines containing beacon from /usr/share/dict/words into /root/beacon-lines.

---

## Question 18 - Archive (clientvm) - 4 pts

Create /root/var-tmp-harbor.tar.bz2 containing /var/tmp.

---

## Question 19 - Shell Script (clientvm) - 4 pts

Create executable script /usr/local/bin/harbor-check that writes the active state of each service listed in /usr/local/share/exam-e/services.lst to /root/harbor-services.txt.

---

## Question 20 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 640 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 21 - Resize Existing LV (clientvm) - 4 pts

Resize /dev/reviewvge/reviewe so the final size is 360 MiB without losing the existing filesystem data.

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

Apply the recommended tuned profile and leave it active.
