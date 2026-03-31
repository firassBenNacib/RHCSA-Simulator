# Mock Exam H: SilverPeak Services Review

## Exam Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-h` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, storage-lvm, containers |

A 22 question RHCSA style mock exam for RHEL 9 that adds package management, boot target work, rich rules, and image inspection.

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

### Question 01 — Client Network
**System:** clientvm

Configure networking on clientvm with the following settings:

IP ADDRESS: 192.168.122.47
NETMASK: 255.255.255.0
GATEWAY: 192.168.122.1
DNS SERVER: 192.168.122.3
HOSTNAME: clientvm.silverpeak.lab

---

### Question 02 — Static Host Entry
**System:** clientvm

Add a persistent hosts entry so registry.silverpeak.lab resolves to 192.168.122.3.

---

### Question 03 — Repositories On Both Systems
**System:** clientvm + servervm

On clientvm and servervm, configure a repository file with the following settings:

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

---

### Question 04 — Apache SELinux Port
**System:** clientvm

Configure the Apache HTTP server on clientvm so that it serves the existing site on TCP port 8181.

Requirements:
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Make the SELinux port label change required for the new port.
- Do not move or relabel the existing document root content.

---

### Question 05 — Users And Group
**System:** clientvm

Create group silverops and users iris and daren with silverops as a supplementary group. Create user hush with /sbin/nologin and no silverops membership.

---

### Question 06 — User Passwords
**System:** clientvm

Set the password of iris, daren, and hush to redhat.

---

### Question 07 — Delegated Sudo
**System:** clientvm

Allow members of silverops to run useradd through sudo, and allow iris to run passwd for other users without a sudo password prompt.

---

### Question 08 — Setgid Directory
**System:** clientvm

Create /srv/silver with group ownership silverops, permissions 2770, and inherited group ownership for new files.

---

### Question 09 — Pwquality Policy
**System:** clientvm

Configure a persistent password quality policy in /etc/security/pwquality.conf.d so that local passwords require a minimum length of 12 and at least 3 character classes.

---

### Question 10 — Per-User Password Aging
**System:** clientvm

Create user agingh with password redhat and configure the account with a maximum password age of 30 days, a minimum age of 2 days, and a warning period of 7 days. Force the user to change the password at the next login.

---

### Question 11 — Chrony Client
**System:** clientvm

Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

---

### Question 12 — Autofs Map
**System:** clientvm

Create user silverremote with password redhat and configure autofs so that the following mount becomes available on demand:

LOCAL PATH: /silver/home/silverremote
REMOTE EXPORT: servervm:/exports/silverhome

---

### Question 13 — Firewalld Rich Rule
**System:** clientvm

Configure a persistent firewalld rich rule that allows TCP port 2222 only from the source network 192.168.122.0/24.

---

### Question 14 — Find And Copy
**System:** clientvm

Find all files under /opt/exam-h/find that are owned by watcherh and were modified within the last 24 hours, then copy them to /root/watcherh-files while preserving the source directory structure.

---

### Question 15 — Grep Filter
**System:** clientvm

Extract lines containing silver from /usr/share/dict/words into /root/silver-lines.

---

### Question 16 — Archive
**System:** clientvm

Create /root/usr-local-h.tar.gz containing /usr/local.

---

### Question 17 — Swap Space
**System:** clientvm

On /dev/sdb, create a 672 MiB swap partition and configure it persistently.

---

### Question 18 — Resize Existing LV
**System:** clientvm

Resize /dev/reviewvgh/reviewh so the final size is 320 MiB without losing the existing file system or data.

---

### Question 19 — Boot Target And Services
**System:** clientvm

Configure clientvm to boot into multi-user.target by default. Ensure rsyslog is enabled and running. If postfix is installed, disable it and stop it.

---

### Question 20 — Install And Remove Packages
**System:** clientvm

Use the prepared local repositories to install the packages tree and dos2unix on clientvm. Remove dos2unix and leave tree installed.

---

### Question 21 — Inspect Container Image
**System:** clientvm

Create user inspecth with password redhat if it does not already exist. As that user, load /opt/rhcsa/container-assets/rhcsa-httpd-base.tar into local storage and write the configured working directory of localhost/rhcsa-httpd-base:latest to /home/inspecth/workdir.txt.

---

### Question 22 — Recommended Tuned Profile
**System:** clientvm

Apply the recommended tuned profile and leave it active.
