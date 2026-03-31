# Mock Exam E: HarborGrid Recovery Review

## Exam Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, software-scheduling-time, storage-lvm, selinux-and-default-perms |

A 22 question RHCSA style mock exam for RHEL 9 that adds pwquality, at scheduling, tuned, and an existing logical volume resize.

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

IP ADDRESS: 192.168.122.37
NETMASK: 255.255.255.0
GATEWAY: 192.168.122.1
DNS SERVER: 192.168.122.3
HOSTNAME: clientvm.harbor.lab

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

## Question 06 — Apache SELinux Port
**System:** clientvm

Configure the Apache HTTP server on clientvm so that it serves the existing site on TCP port 8181.

Requirements:
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Make the SELinux change required for the new port.
- Do not alter the existing site content.

---

## Question 07 — Users And Group
**System:** clientvm

Create group harborops and users lena and ivor with harborops as a supplementary group. Create user hush with /sbin/nologin and no harborops membership.

---

## Question 08 — User Passwords
**System:** clientvm

Set the password of lena, ivor, and hush to redhat.

---

## Question 09 — Delegated Sudo
**System:** clientvm

Allow members of harborops to run useradd through sudo, and allow lena to restart httpd through sudo without a password prompt.

---

## Question 10 — Setgid Directory
**System:** clientvm

Create /srv/harbor with group ownership harborops, permissions 2770, and inherited group ownership for new files.

---

## Question 11 — Pwquality Policy
**System:** clientvm

Configure a persistent password quality policy in /etc/security/pwquality.conf.d so that local passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 12 — At Job
**System:** clientvm

Create a one-time at job as user ivor that appends the text Harbor queued to /home/ivor/at.log two minutes from now. Ensure the atd service is enabled and running.

---

## Question 13 — Chrony Client
**System:** clientvm

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

## Question 14 — Autofs Map
**System:** clientvm

Create user harborremote with password redhat and configure autofs so that the following mount becomes available on demand:

LOCAL PATH: /harbor/home/harborremote
REMOTE EXPORT: servervm:/exports/harborhome

---

## Question 15 — Fixed UID User
**System:** clientvm

Create user maple551 with UID 4551 and set its password to redhat.

---

## Question 16 — Find And Copy
**System:** clientvm

Find all files under /opt/exam-e/find that are owned by scoutte and were modified within the last 24 hours. Copy them to /root/scoutte-files while preserving the source directory structure.

---

## Question 17 — Grep Filter
**System:** clientvm

Extract lines containing beacon from /usr/share/dict/words into /root/beacon-lines.

---

## Question 18 — Archive
**System:** clientvm

Create /root/var-tmp-harbor.tar.bz2 containing /var/tmp.

---

## Question 19 — Shell Script
**System:** clientvm

Create executable script /usr/local/bin/harbor-check that writes the active state of each service listed in /usr/local/share/exam-e/services.lst to /root/harbor-services.txt.

---

## Question 20 — Swap Space
**System:** clientvm

On /dev/sdb, create a 640 MiB swap partition.

Requirements:
- Enable it immediately.
- Configure it persistently.

---

## Question 21 — Resize Existing LV
**System:** clientvm

Resize /dev/reviewvge/reviewe so the final size is 360 MiB without losing the existing filesystem data.

---

## Question 22 — Recommended Tuned Profile
**System:** clientvm

Apply the recommended tuned profile and leave it active.
