# Mock Exam A: OpsEdge Integrated Review

## Exam Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-a` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, storage-lvm, containers |

A 22 task RHCSA style mock exam for RHEL 9 with recovery, repositories, SELinux, storage, and rootless containers.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

### Question 01 — Root Recovery
**System:** clientvm

Recover root access on clientvm from the console.

Set the root password to: redhat

---

### Question 02 — Client Network
**System:** clientvm

Configure networking on clientvm with the following settings:

IP ADDRESS: 192.168.122.26
NETMASK: 255.255.255.0
GATEWAY: 192.168.122.1
DNS SERVER: 192.168.122.3
HOSTNAME: clientvm.opsedge.lab

---

### Question 03 — Bootloader Kernel Argument
**System:** clientvm

Configure the bootloader on clientvm so that every installed kernel boots with the kernel argument audit=1.

Requirements:
- The change must persist across reboots.
- Do not rely on a one-time edit at the GRUB menu.

---

### Question 04 — Client Repositories
**System:** clientvm

Configure a repository file on clientvm with the following settings:

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

---

### Question 05 — Server Repositories
**System:** servervm

Configure the same repository file on servervm.

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

---

### Question 06 — Apache SELinux Port
**System:** clientvm

Configure the Apache HTTP server on clientvm so that it serves the existing site on TCP port 8282.

Requirements:
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Make the SELinux change required for the new port.
- Do not move or relabel the existing document root content.

---

### Question 07 — Users And Group
**System:** clientvm

Create group sysopsa and users violet and amber with sysopsa as a supplementary group. Create user frost with /sbin/nologin and no sysopsa membership.

---

### Question 08 — User Passwords
**System:** clientvm

Set the password of violet, amber, and frost to redhat.

---

### Question 09 — Delegated Sudo
**System:** clientvm

Allow members of sysopsa to run useradd through sudo, and allow violet to run passwd for other users without a sudo password prompt.

---

### Question 10 — Setgid Directory
**System:** clientvm

Create /srv/sysopsa with group ownership sysopsa, no access for other users, and automatic group inheritance for new files.

---

### Question 11 — Cron Logger
**System:** clientvm

Configure a cron job for amber that runs every 2 minutes and logs the message "OpsEdge tick".

---

### Question 12 — Chrony Client
**System:** clientvm

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

### Question 13 — Autofs Map
**System:** clientvm

Create user netopsa with password redhat and configure autofs so that the following mount becomes available on demand:

LOCAL PATH: /researcha/netopsa
REMOTE EXPORT: servervm:/exports/researcha

---

### Question 14 — Fixed UID User
**System:** clientvm

Create user ash420 with UID 4420 and set its password to redhat.

---

### Question 15 — Find And Copy
**System:** clientvm

Find all files under /opt/exam-a/find that are owned by amber and were modified within the last 24 hours, then copy them to /root/amber-files while preserving the source directory structure.

---

### Question 16 — Grep Filter
**System:** clientvm

Extract lines containing delta from /usr/share/dict/words into /root/delta-lines.

---

### Question 17 — Archive
**System:** clientvm

Create /root/etc-opsa.tar.bz2 containing /etc.

---

### Question 18 — Service Audit Script
**System:** clientvm

Create /usr/local/bin/opsa-report as an executable script that writes the status of each service listed in /usr/local/share/exam-a/services.lst to /root/opsa-services.txt.

---

### Question 19 — Swap Space
**System:** clientvm

On /dev/sdb, create a 512 MiB swap partition.

Requirements:
- Enable it immediately.
- Configure it persistently.

---

### Question 20 — Resize Existing LV
**System:** clientvm

Resize /dev/reviewvga/reviewa so the final size is 320 MiB without losing the existing filesystem data.

---

### Question 21 — Rootless Container
**System:** clientvm

As user oriona, build localhost/opsa-web:latest from /opt/rhcsa/workspaces/exam-a/Containerfile, then run container pdfa with /opt/ina mounted to /data/input and /opt/outa mounted to /data/output.

---

### Question 22 — Container Autostart
**System:** clientvm

Generate and enable a systemd user service for container pdfa and enable lingering for oriona.
