# Mock Exam E: HarborGrid Services Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, software-management, filesystems-and-autofs, users-sudo-ssh, storage-lvm |

A 22 task RHCSA style mock exam focused on offline repositories, Apache document roots, ACLs, NFS, and storage maintenance.

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

- **IP Address:** 192.168.122.37
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.harborgrid.lab

---

## Question 02 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so registry.harbor.lab resolves to 192.168.122.3.

---

## Question 03 - Client Repositories (clientvm) - 5 pts

Configure a repository file on clientvm with BaseOS and AppStream served from servervm, enabled, and with gpgcheck disabled.

---

## Question 04 - Server Repositories (servervm) - 5 pts

Configure the same repository file on servervm.

---

## Question 05 - Apache Custom Docroot (clientvm) - 5 pts

Configure Apache on clientvm so it serves /srv/harbor-web on TCP port 8181.

**Requirements**
- Start automatically at boot.
- Open the port permanently in the firewall.
- Apply the SELinux changes needed for the custom document root and port.

---

## Question 06 - Harbor Users (clientvm) - 5 pts

Create group harborops and create users lena and ivor with harborops as a supplementary group at creation time. Set the password of both users to cinder9.

---

## Question 07 - Password Aging (clientvm) - 5 pts

Set password aging for ivor to maximum 30 days, minimum 2 days, and warning 7 days.

---

## Question 08 - Default ACL Directory (clientvm) - 5 pts

Create /srv/harbor-drop owned by root:harborops with mode 2770 and a default ACL that grants harborops rwx on new files and directories.

---

## Question 09 - No-Home Remote User (clientvm) - 5 pts

Create user harborremote without a home directory, with shell /sbin/nologin, and set its password to cinder9.

---

## Question 10 - Pwquality Policy (clientvm) - 5 pts

Configure pwquality so passwords require a minimum length of 12 and at least 3 character classes.

---

## Question 11 - At Job (clientvm) - 5 pts

Queue a one-time at job as user ivor that appends the message "HarborGrid tick" to /root/harbor-at.log in 2 minutes.

---

## Question 12 - Direct NFS Mount (clientvm) - 5 pts

- **Persistently mount servervm:** /exports/harborhome on /mnt/harborhome using /etc/fstab.

---

## Question 13 - Persistent Journal (servervm) - 4 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 14 - Per-User Login Message (clientvm) - 4 pts

Append a login message for ivor to ~/.bash_profile that prints "HarborGrid access" when ivor logs in.

---

## Question 15 - Fixed UID User (clientvm) - 4 pts

Create user maple551 with UID 4551, no home directory, shell /sbin/nologin, and password cinder9.

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
