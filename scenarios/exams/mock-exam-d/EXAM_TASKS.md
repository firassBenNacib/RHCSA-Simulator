# Mock Exam D: SummitLine Operations Review - Exam Tasks
Scenario ID: mock-exam-d
Mode: Exam
Time limit: 150 minutes
Objectives: networking-and-firewall, storage-lvm, users-sudo-ssh, containers

A 22 question RHCSA style mock exam for RHEL 9 that adds default ACLs, umask tuning, password aging, and a full create mount storage task.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.
- Use the exact scenario variables shown in each question.
- Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm)
Configure networking on clientvm with the following settings:

IP ADDRESS: 192.168.122.36
NETMASK: 255.255.255.0
GATEWAY: 192.168.122.1
DNS SERVER: 192.168.122.3
HOSTNAME: clientvm.summit.lab

## Question 02 - Static Host Entry (clientvm)
Add a persistent hosts entry so mirror.summit.lab resolves to 192.168.122.3.

## Question 03 - Client Repositories (clientvm)
Configure a repository file on clientvm with the following settings:

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

## Question 04 - Server Repositories (servervm)
Configure the same repository file on servervm.

BaseOS: http://servervm/repo/BaseOS/
AppStream: http://servervm/repo/AppStream/
gpgcheck: disabled
Repositories: enabled

## Question 05 - Apache Custom Docroot (clientvm)
Configure the Apache HTTP server on clientvm so that it serves content from /srv/summit-web on TCP port 8085.

Requirements:
- Start the service automatically at boot.
- Open the port permanently in the firewall.
- Configure the required SELinux file context and port label.
- Do not modify /srv/summit-web/index.html.

## Question 06 - Users And Group (clientvm)
Create group summitops and users kara and miles with summitops as a supplementary group. Create user zero with /sbin/nologin and no summitops membership.

## Question 07 - User Passwords (clientvm)
Set the password of kara, miles, and zero to redhat.

## Question 08 - Delegated Sudo (clientvm)
Allow members of summitops to run useradd through sudo, and allow kara to run passwd for other users without a sudo password prompt.

## Question 09 - Shared Directory With Default ACL (clientvm)
Create user auditord with password redhat. Then create /projects/summit with group ownership summitops, permissions 2770, inherited group ownership for new files, and a default ACL that grants auditord rwx on new content.

## Question 10 - User Umask (clientvm)
Configure user miles so that new regular files are created with mode 0640 and new directories are created with mode 0750 when the user logs in.

## Question 11 - Password Aging Defaults (clientvm)
Configure the default password aging policy for newly created local users with the following values:

PASS_MAX_DAYS: 45
PASS_MIN_DAYS: 2
PASS_WARN_AGE: 10

Then create user trainee54, set its password to redhat, and ensure it inherits the defaults.

## Question 12 - Cron Logger (clientvm)
Configure a cron job for miles that runs every 15 minutes and logs the message "Summit exam".

## Question 13 - Chrony Client (clientvm)
Configure chrony on clientvm so it synchronizes only with servervm and starts automatically at boot.

## Question 14 - Autofs Map (clientvm)
Create user summitremote with password redhat and configure autofs so that the following mount becomes available on demand:

LOCAL PATH: /summit-home/summitremote
REMOTE EXPORT: servervm:/exports/summit-home

## Question 15 - Fixed UID User (clientvm)
Create user cedar540 with UID 4540 and set its password to redhat.

## Question 16 - Find And Copy (clientvm)
Find all files under /opt/exam-d/find that are owned by foragerd and were modified within the last 24 hours. Copy them to /root/miles-files while preserving the source directory structure.

## Question 17 - Grep Filter (clientvm)
Extract lines containing alpha from /usr/share/dict/words into /root/alpha-lines.

## Question 18 - Archive (clientvm)
Create /root/summit-etc.tar.gz containing /etc.

## Question 19 - Shell Script (clientvm)
Create executable script /usr/local/bin/summit-scan that writes the active state of each unit listed in /usr/local/share/exam-d/units.lst to /root/summit-units.txt.

## Question 20 - Swap Space (clientvm)
On /dev/sdb, create a 768 MiB swap partition.

Requirements:
- Enable it immediately.
- Configure it persistently.

## Question 21 - Create And Mount LV (clientvm)
On /dev/sdc, create a volume group summitvg with a physical extent size of 16 MiB and a logical volume summitlv of 40 extents. Format it with ext4 and mount it persistently on /mnt/summitlv.

## Question 22 - Rootless Container Autostart (clientvm)
As user neriad, build localhost/summit-web:latest from /opt/rhcsa/workspaces/exam-d/Containerfile, run container pdfd with /opt/ind mounted to /data/input and /opt/outd mounted to /data/output, then generate and enable the systemd user service so it starts after reboot. Enable lingering for neriad.
