# Mock Exam A

## Exam Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-a` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam focused on recovery, repositories, Apache, sudo delegation, storage, and rootless containers.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (clientvm) - 5 pts

Recover root access on clientvm from the console.

Set the root password to: cinder9

---

## Question 02 - Client Network (clientvm) - 5 pts

Configure networking on clientvm with the following settings:

- **IP Address:** 192.168.122.26
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.exam-a.lab

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

Configure the bootloader on clientvm so every installed kernel boots with the kernel argument audit_backlog_limit=8192.

**Requirements**
- The change must persist across reboots.
- Do not rely on a one-time GRUB edit.

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

Configure Apache on clientvm so it serves the existing site on TCP port 8282.

**Requirements**
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Make the SELinux change required for the new port.
- Leave the existing document root content in place.

---

## Question 07 - Users And Group (clientvm) - 5 pts

Create group sysopsa and users violet and amber with sysopsa as a supplementary group at creation time. Create user frost without a home directory and with login shell /sbin/nologin.

---

## Question 08 - User Passwords (clientvm) - 5 pts

Set the password of violet, amber, and frost to cinder9.

---

## Question 09 - Delegated Sudo (clientvm) - 5 pts

Allow members of sysopsa to run /usr/sbin/useradd through sudo. Allow violet to run /usr/bin/passwd for other users without a sudo password prompt. Use sudoers drop-ins.

---

## Question 10 - Setgid Directory (clientvm) - 5 pts

Create /srv/sysopsa owned by root:sysopsa with mode 2770 so new files inherit the sysopsa group.

---

## Question 11 - Cron Logger (clientvm) - 5 pts

Configure a cron job for amber that runs every 2 minutes and logs the message "exam-a tick".

---

## Question 12 - Host Entry (clientvm) - 5 pts

Add a persistent hosts entry on clientvm so api.exam-a.lab resolves to 192.168.122.3.

---

## Question 13 - Swap Space (clientvm) - 4 pts

On /dev/sdb, create a 512 MiB swap partition.

**Requirements**
- Enable it immediately.
- Configure it persistently.

---

## Question 14 - Resize Existing LV (clientvm) - 4 pts

Resize /dev/reviewvga/reviewa so the final size is 320 MiB without losing the existing filesystem data.

---

## Question 15 - Rootless Container (clientvm) - 4 pts

As user oriona, build localhost/opsa-web:latest from /opt/rhcsa/workspaces/exam-a/Containerfile, then run container pdfa with /opt/ina mounted to /data/input and /opt/outa mounted to /data/output.

---

## Question 16 - Container Autostart (clientvm) - 4 pts

Generate and enable a systemd user service for container pdfa and enable lingering for oriona.

---

## Question 17 - Persistent Journal (servervm) - 4 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 18 - Persistent Journal (servervm) - 4 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 19 - Persistent Journal (servervm) - 4 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 20 - Persistent Journal (servervm) - 4 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 21 - Persistent Journal (servervm) - 4 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.

---

## Question 22 - Persistent Journal (servervm) - 4 pts

On servervm, enable persistent systemd journal storage and restart systemd-journald.
