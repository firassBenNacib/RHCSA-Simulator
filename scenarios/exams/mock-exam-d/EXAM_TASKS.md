# Mock Exam D: SummitLine Operations Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-d` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, storage-lvm, users-sudo-ssh, containers |

A 22 question RHCSA style mock exam for RHEL 9 that adds default ACLs, umask tuning, password aging, and a full create mount storage task.

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

- **IP Address:** 192.168.122.36
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.summit.lab

---

## Question 02 - Static Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so mirror.summit.lab resolves to 192.168.122.3.

---

## Question 03 - Client Repositories (clientvm) - 5 pts

Configure a repository file on clientvm with the following settings:

- **BaseOS:** http://servervm/repo/BaseOS/
- **AppStream:** http://servervm/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 04 - Server Repositories (servervm) - 5 pts

Configure the same repository file on servervm.

- **BaseOS:** http://servervm/repo/BaseOS/
- **AppStream:** http://servervm/repo/AppStream/
- **gpgcheck:** disabled
- **Repositories:** enabled

---

## Question 05 - Apache Custom Docroot (clientvm) - 5 pts

Configure the Apache HTTP server on clientvm so that it serves content from /srv/summit-web on TCP port 8085.

**Requirements**
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Configure the required SELinux file context and port label.
- Do not modify /srv/summit-web/index.html.

---

## Question 06 - Users And Group (clientvm) - 5 pts

Create group summitops and users kara and miles with summitops as a supplementary group. Create user zero with /sbin/nologin and no summitops membership.

---

## Question 07 - User Passwords (clientvm) - 5 pts

Set the password of kara, miles, and zero to cinder9.

---

## Question 08 - Delegated Sudo (clientvm) - 5 pts

Allow members of summitops to run useradd through sudo, and allow kara to run passwd for other users without a sudo password prompt.

---

## Question 09 - Shared Directory With Default ACL (clientvm) - 5 pts

Create user auditord with password cinder9. Then create /projects/summit with group ownership summitops, permissions 2770, inherited group ownership for new files, and a default ACL that grants auditord rwx on new content.

---

## Question 10 - User Umask (clientvm) - 5 pts

Configure user miles so that new regular files are created with mode 0640 and new directories are created with mode 0750 when the user logs in.

---

## Question 11 - Password Aging Defaults (clientvm) - 5 pts

Configure the default password aging policy for newly created local users with the following values:

- **Pass_Max_Days:** 45
- **Pass_Min_Days:** 2
- **Pass_Warn_Age:** 10

Then create user trainee54, set its password to cinder9, and ensure it inherits the defaults.

---

## Question 12 - Cron Logger (clientvm) - 5 pts

Configure a cron job for miles that runs every 15 minutes and logs the message "Summit exam".

---

## Question 13 - Chrony Client (clientvm) - 4 pts

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

## Question 14 - Autofs Map (clientvm) - 4 pts

Create user summitremote with password cinder9 and configure autofs so that the following mount becomes available on demand:

- **Local Path:** /summit-home/summitremote
- **Remote Export:** servervm:/exports/summit-home

---

## Question 15 - Fixed UID User (clientvm) - 4 pts

Create user cedar540 with UID 4540 and set its password to cinder9.

---

## Question 16 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-d/find that are owned by foragerd and were modified within the last 24 hours. Copy them to /root/miles-files while preserving the source directory structure.

---

## Question 17 - Grep Filter (clientvm) - 4 pts

Extract lines containing alpha from /usr/share/dict/words into /root/alpha-lines.

---

## Question 18 - Archive (clientvm) - 4 pts

Create /root/summit-etc.tar.gz containing /etc.

---

## Question 19 - Shell Script (clientvm) - 4 pts

Create executable script /usr/local/bin/summit-scan that writes the active state of each unit listed in /usr/local/share/exam-d/units.lst to /root/summit-units.txt.

---

## Question 20 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 768 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 21 - Create And Mount LV (clientvm) - 4 pts

On /dev/sdc, create a volume group summitvg with a physical extent size of 16 MiB and a logical volume summitlv of 40 extents. Format it with ext4 and mount it persistently on /mnt/summitlv.

---

## Question 22 - Rootless Container Autostart (clientvm) - 4 pts

As user neriad, build localhost/summit-web:latest from /opt/rhcsa/workspaces/exam-d/Containerfile, run container pdfd with /opt/ind mounted to /data/input and /opt/outd mounted to /data/output, then generate and enable the systemd user service so it starts after reboot. Enable lingering for neriad.
