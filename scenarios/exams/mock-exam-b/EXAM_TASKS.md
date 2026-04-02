# Mock Exam B: CoreMesh Service Review

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, storage-lvm, containers |

A second 22 task RHCSA style mock exam with distinct variables and combined tasks.

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

- **IP Address:** 192.168.122.27
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.coremesh.lab

---

## Question 02 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry so registry.coremesh.lab resolves to 192.168.122.3.

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

## Question 05 - Apache Firewall SELinux (clientvm) - 5 pts

Configure the Apache HTTP server on clientvm so that it serves the existing site on TCP port 8383.

**Requirements**
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Allow the port in SELinux.
- Do not alter the existing site content.

---

## Question 06 - Users And Group (clientvm) - 5 pts

Create group platformb and users mira and jonas with platformb as a supplementary group. Create user noel with /sbin/nologin and no platformb membership.

---

## Question 07 - User Passwords (clientvm) - 5 pts

Set the password of mira, jonas, and noel to cinder9.

---

## Question 08 - Delegated Sudo (clientvm) - 5 pts

Allow members of platformb to run useradd with sudo, and allow mira to restart httpd with sudo and no password prompt.

---

## Question 09 - Setgid Directory (clientvm) - 5 pts

Create /srv/platformb with group ownership platformb, mode 2770, and inherited group ownership for new files.

---

## Question 10 - Cron Logger (clientvm) - 5 pts

Configure a cron job for mira that runs every minute and logs the message "CoreMesh exam".

---

## Question 11 - Chrony Client (clientvm) - 5 pts

Configure chrony on clientvm so it synchronizes only with servervm.

---

## Question 12 - Autofs Map (clientvm) - 5 pts

Create user meshremote with password cinder9 and configure autofs so that the following mount becomes available on demand:

- **Local Path:** /meshb/meshremote
- **Remote Export:** servervm:/exports/meshb

---

## Question 13 - Fixed UID User (clientvm) - 4 pts

Create user cato421 with UID 4421 and set its password to cinder9.

---

## Question 14 - Find And Copy (clientvm) - 4 pts

Find all files under /opt/exam-b/find that are owned by mira and were modified in the last 24 hours, then copy them to /root/mira-files while preserving the directory structure.

---

## Question 15 - Grep Filter (clientvm) - 4 pts

Extract lines containing proto from /usr/share/dict/words into /root/proto-lines.

---

## Question 16 - Archive (clientvm) - 4 pts

Create /root/usr-local-b.tar.bz2 containing /usr/local.

---

## Question 17 - Unit Status Script (clientvm) - 4 pts

Create executable script /usr/local/bin/corecheck that writes the active state of each unit listed in /usr/local/share/exam-b/units.lst to /root/coremesh-units.txt.

---

## Question 18 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 600 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 19 - Resize Existing LV (clientvm) - 4 pts

Resize /dev/reviewvgb/reviewb so the final size is 300 MiB without losing data.

---

## Question 20 - Tuned Profile (clientvm) - 4 pts

Apply the recommended tuned profile and leave it active.

---

## Question 21 - Rootless Container (clientvm) - 4 pts

As user lyrab, build localhost/coremesh-web:latest from /opt/rhcsa/workspaces/exam-b/Containerfile, then run container pdfb with /opt/inb mounted to /data/input and /opt/outb mounted to /data/output.

---

## Question 22 - Container Autostart (clientvm) - 4 pts

Generate and enable a systemd user service for pdfb and enable lingering for lyrab.
