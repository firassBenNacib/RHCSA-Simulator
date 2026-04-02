# Mock Exam F: AuroraPath Access Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-f` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, storage-lvm, users-sudo-ssh, containers |

A 22 question RHCSA style mock exam for RHEL 9 that adds key based SSH access, a restrictive rich rule, an alternate umask, and another create mount container build workflow.

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

- **IP Address:** 192.168.122.38
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.aurora.lab

---

## Question 02 - Static Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so db.aurora.lab resolves to 192.168.122.3.

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

Configure the Apache HTTP server on clientvm so that it serves content from /srv/aurora-web on TCP port 9090.

**Requirements**
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Configure the required SELinux file context and port label.
- Do not modify /srv/aurora-web/index.html.

---

## Question 06 - Users And Group (clientvm) - 5 pts

Create group auroraops and users elio and risa with auroraops as a supplementary group. Create user nox with /sbin/nologin and no auroraops membership.

---

## Question 07 - User Passwords (clientvm) - 5 pts

Set the password of elio, risa, and nox to cinder9.

---

## Question 08 - Delegated Sudo (clientvm) - 5 pts

Allow members of auroraops to run useradd through sudo, and allow elio to run passwd for other users without a sudo password prompt.

---

## Question 09 - Shared Directory With Default ACL (clientvm) - 5 pts

Create user auditf with password cinder9. Then create /data/aurora with group ownership auroraops, permissions 2770, inherited group ownership for new files, and a default ACL that grants auditf rwx on new content.

---

## Question 10 - User Umask (clientvm) - 5 pts

Configure user risa so that new regular files are created with mode 0600 and new directories are created with mode 0700 when the user logs in.

---

## Question 11 - SSH Key Authentication (clientvm + servervm) - 5 pts

Create user opsf on clientvm and user backupf on servervm. Set the password of both users to cinder9. Then configure key-based SSH authentication so opsf on clientvm can log in to backupf@servervm without a password prompt.

---

## Question 12 - Firewalld Rich Rule (clientvm) - 5 pts

Configure a persistent firewalld rich rule that allows TCP port 2222 only from the source network 192.168.122.0/24. Reload firewalld and verify the rule is active.

---

## Question 13 - Chrony Client (clientvm) - 4 pts

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

## Question 14 - Autofs Map (clientvm) - 4 pts

Create user aurorarem with password cinder9 and configure autofs so that the following mount becomes available on demand:

- **Local Path:** /aurora/home/aurorarem
- **Remote Export:** servervm:/exports/aurorahome

---

## Question 15 - Fixed UID User (clientvm) - 4 pts

Create user pine560 with UID 4560 and set its password to cinder9.

---

## Question 16 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-f/find that are owned by seekerf and were modified within the last 24 hours. Copy them to /root/seekerf-files while preserving the source directory structure.

---

## Question 17 - Grep Filter (clientvm) - 4 pts

Extract lines containing comet from /usr/share/dict/words into /root/comet-lines.

---

## Question 18 - Archive (clientvm) - 4 pts

Create /root/usr-local-f.tar.gz containing /usr/local.

---

## Question 19 - Shell Script (clientvm) - 4 pts

Create executable script /usr/local/bin/aurora-report that writes the active state of each unit listed in /usr/local/share/exam-f/units.lst to /root/aurora-units.txt.

---

## Question 20 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 704 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 21 - Create And Mount LV (clientvm) - 4 pts

On /dev/sdc, create a volume group auroravg with a physical extent size of 8 MiB and a logical volume auroralv of 50 extents. Format it with xfs and mount it persistently on /mnt/auroralv.

---

## Question 22 - Rootless Container Autostart (clientvm) - 4 pts

As user solf, build localhost/aurora-web:latest from /opt/rhcsa/workspaces/exam-f/Containerfile, run container pdff with /opt/inf mounted to /data/input and /opt/outf mounted to /data/output, then generate and enable the systemd user service so it starts after reboot. Enable lingering for solf.
