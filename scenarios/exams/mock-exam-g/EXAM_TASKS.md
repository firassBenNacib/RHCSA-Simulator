# Mock Exam G: DeltaForge Recovery Review

## Exam Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-g` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, systemd-and-processes, storage-lvm |

A 22 question RHCSA style mock exam for RHEL 9 that adds persistent journals, direct NFS mounting, secure copy, and process scheduling work.

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

IP ADDRESS: 192.168.122.46
NETMASK: 255.255.255.0
GATEWAY: 192.168.122.1
DNS SERVER: 192.168.122.3
HOSTNAME: clientvm.deltaforge.lab

---

### Question 03 — Bootloader Kernel Argument
**System:** clientvm

Configure the bootloader on clientvm so that every installed kernel boots with the kernel argument audit=1.

Requirements:
- The change must persist across reboots.
- Do not rely on a one-time edit at the GRUB menu.

---

### Question 04 — Repositories On Both Systems
**System:** clientvm + servervm

On clientvm and servervm, configure a repository file with the following settings:

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

---

### Question 05 — Apache Custom Docroot
**System:** clientvm

Configure the Apache HTTP server on clientvm so that it serves content from /srv/delta-web on TCP port 8086.

Requirements:
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Configure the SELinux file context and SELinux port label required for the new location and port.

---

### Question 06 — Users And Group
**System:** clientvm

Create group deltaops and users gwen and pavel with deltaops as a supplementary group. Create user sable with /sbin/nologin and no deltaops membership.

---

### Question 07 — User Passwords
**System:** clientvm

Set the password of gwen, pavel, and sable to redhat.

---

### Question 08 — Delegated Sudo
**System:** clientvm

Allow members of deltaops to run useradd through sudo, and allow gwen to run passwd for other users without a sudo password prompt.

---

### Question 09 — Shared Directory With Default ACL
**System:** clientvm

Create user auditg with password redhat. Then create /projects/delta with group ownership deltaops, mode 2770, and a default ACL that gives auditg read write execute access to new content.

---

### Question 10 — User Umask
**System:** clientvm

Configure user pavel so that new regular files are created with mode 0640 and new directories are created with mode 0750.

---

### Question 11 — At Job
**System:** clientvm

Create a one-time at job as user pavel that appends the text Delta queued to /home/pavel/at-g.log two minutes from now. Ensure the atd service is enabled and running.

---

### Question 12 — Chrony Client
**System:** clientvm

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

### Question 13 — Direct NFS Mount
**System:** clientvm

Mount the server export servervm:/exports/delta-home persistently on clientvm at /mnt/delta-home using NFS.

---

### Question 14 — SSH Key And Secure Copy
**System:** servervm

Create user copyg on both systems with password redhat. Then configure key based SSH access for copyg from clientvm to servervm and copy /home/copyg/payload.txt to /home/copyg/inbox/ on servervm with scp.

---

### Question 15 — Find And Copy
**System:** clientvm

Find all files under /opt/exam-g/find that are owned by trackerg and were modified within the last 24 hours, then copy them to /root/trackerg-files while preserving the source directory structure.

---

### Question 16 — Grep Filter
**System:** clientvm

Extract lines containing ember from /usr/share/dict/words into /root/ember-lines.

---

### Question 17 — Archive
**System:** clientvm

Create /root/etc-g.tar.bz2 containing /etc.

---

### Question 18 — Persistent Journal
**System:** clientvm

Configure journald on clientvm so logs are stored persistently across reboots.

---

### Question 19 — Process Renice And Kill
**System:** clientvm

User workerg has a CPU-bound process whose PID is stored in /home/workerg/cpu.pid and a sleep process whose PID is stored in /home/workerg/sleep.pid. Terminate the CPU-bound process and change the nice value of the sleep process to 10.

---

### Question 20 — Swap Space
**System:** clientvm

On /dev/sdb, create a 736 MiB swap partition and configure it persistently.

---

### Question 21 — Create And Mount LV
**System:** clientvm

On /dev/sdc, create a volume group deltavg with a physical extent size of 16 MiB and a logical volume deltalv with 40 extents. Format it with ext4 and mount it persistently at /mnt/deltalv.

---

### Question 22 — Rootless Container Autostart
**System:** clientvm

As user solg, build localhost/delta-web:latest from /opt/rhcsa/workspaces/exam-g/Containerfile. Run the container as pdfg with /opt/ing mounted to /data/input and /opt/outg mounted to /data/output. Generate and enable a systemd user service for that container and enable lingering for solg.
