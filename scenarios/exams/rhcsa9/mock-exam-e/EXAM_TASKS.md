# Mock Exam E

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, software-management, filesystems-and-autofs, users-sudo-ssh, storage-lvm |

A 22-task RHCSA practice mock exam focused on offline repositories, Apache document roots, ACLs, NFS, and storage maintenance.

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

- **IP Address:** 192.168.122.37
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **Dns:** 192.168.122.3
- **Hostname:** client.exam-e.lab

---

## Question 02 - Host Entry (client) - 5 pts

On client, add a persistent hosts entry so registry.exam-e.lab resolves to 192.168.122.3.

---

## Question 03 - Client Repositories (client) - 5 pts

On client, configure a repository file on client with BaseOS and AppStream served from server, enabled, and with gpgcheck disabled.

---

## Question 04 - Server Repositories (server) - 5 pts

On server, configure the same repository file on server.

---

## Question 05 - Apache Custom Docroot (client) - 5 pts

On client, configure Apache on client so it serves /srv/harbor-web on TCP port 8181.

**Requirements**
- Start automatically at boot.
- Open the port permanently in the firewall.
- Apply the SELinux changes needed for the custom document root and port.

---

## Question 06 - Harbor Users (client) - 5 pts

On client, create group harborops and create users lena and ivor with harborops as a supplementary group at creation time. Set the password of both users to cinder9.

---

## Question 07 - Password Aging (client) - 5 pts

On client, set password aging for ivor to maximum 30 days, minimum 2 days, and warning 7 days.

---

## Question 08 - Default ACL Directory (client) - 5 pts

On client, create /srv/harbor-drop owned by root:harborops with mode 2770 and a default ACL that grants harborops rwx on new files and directories.

---

## Question 09 - No-Home Remote User (client) - 5 pts

On client, create user harborremote without a home directory, with shell /sbin/nologin, and set its password to cinder9.

---

## Question 10 - Pwquality Policy (client) - 5 pts

On client, configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 11 - At Job (client) - 5 pts

On client, queue a one-time at job as user ivor that appends the message "exam-e tick" to /root/exam-e-at.log in 2 minutes.

---

## Question 12 - Direct NFS Mount (client + server) - 5 pts

On client, persistently mount server:/exports/harborhome on /mnt/harborhome using /etc/fstab.

---

## Question 13 - Persistent Journal (server) - 4 pts

On server, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 14 - Per-User Login Message (client) - 4 pts

On client, append a login message for ivor to ~/.bash_profile that prints "exam-e access" when ivor logs in.

---

## Question 15 - Fixed UID User (client) - 4 pts

On client, create user maple551 with UID 4551, no home directory, shell /sbin/nologin, and password cinder9.

---

## Question 16 - Find and Copy (client) - 4 pts

On client, find all files under /opt/exam-e/find that are owned by scoutte and were modified within the last 24 hours. Copy them to /root/scoutte-files while preserving the source directory structure.

---

## Question 17 - Grep Filter (client) - 4 pts

On client, extract lines containing beacon from /usr/share/dict/words into /root/beacon-lines.

---

## Question 18 - Archive (client) - 4 pts

On client, create /root/var-tmp-harbor.tar.bz2 containing /var/tmp.

---

## Question 19 - Shell Script (client) - 4 pts

On client, create executable script /usr/local/bin/harbor-check that writes the active state of each service listed in /usr/local/share/exam-e/services.lst to /root/harbor-services.txt.

---

## Question 20 - Swap Space (client) - 4 pts

On client, on /dev/sdb, create a 640 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 21 - Resize Existing LV (client) - 4 pts

On client, resize /dev/reviewvge/reviewe so the final size is 360 MiB without losing the existing filesystem data.

---

## Question 22 - Recommended Tuned Profile (client) - 4 pts

On client, apply the recommended tuned profile and leave it active.
