# Mock Exam G: DeltaForge Recovery Review

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-g` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, networking-and-firewall, processes-logs-tuning, storage-lvm |

A 22 question RHCSA style mock exam for RHEL 9 that adds persistent journals, direct NFS mounting, secure copy, and process scheduling work.

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

## Question 01 - Root Recovery (clientvm) - 5 pts

```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

## Question 02 - Client Network (clientvm) - 5 pts

```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.46/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.deltaforge.lab
```

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
grubby --info=ALL | grep -E "^kernel|^args"
```

---

## Question 04 - Repositories On Both Systems (clientvm + servervm) - 5 pts

```bash
# On clientvm
vim /etc/yum.repos.d/delta.repo
[delta-baseos]
name=Delta BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[delta-appstream]
name=Delta AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
:wq
dnf clean all
# On servervm
vim /etc/yum.repos.d/delta.repo
[delta-baseos]
name=Delta BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[delta-appstream]
name=Delta AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
:wq
dnf clean all
```

---

## Question 05 - Apache Custom Docroot (clientvm) - 5 pts

```bash
vim /etc/httpd/conf.d/delta.conf
Listen 8086
<VirtualHost *:8086>
DocumentRoot "/srv/delta-web"
<Directory "/srv/delta-web">
Require all granted
</Directory>
</VirtualHost>
:wq
semanage fcontext -a -t httpd_sys_content_t "/srv/delta-web(/.*)?"
restorecon -Rv /srv/delta-web
semanage port -a -t http_port_t -p tcp 8086
firewall-cmd --permanent --add-port=8086/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

---

## Question 06 - Users And Group (clientvm) - 5 pts

```bash
groupadd deltaops
useradd -m gwen
useradd -m pavel
useradd -m -s /sbin/nologin sable
usermod -aG deltaops gwen
usermod -aG deltaops pavel
```

---

## Question 07 - User Passwords (clientvm) - 5 pts

```bash
passwd gwen
# enter: cinder9
passwd pavel
# enter: cinder9
passwd sable
# enter: cinder9
```

---

## Question 08 - Delegated Sudo (clientvm) - 5 pts

```bash
visudo -f /etc/sudoers.d/deltaops
%deltaops ALL=(ALL) /usr/sbin/useradd
:wq
visudo -f /etc/sudoers.d/gwen-passwd
gwen ALL=(ALL) NOPASSWD: /usr/bin/passwd
:wq
```

---

## Question 09 - Shared Directory With Default ACL (clientvm) - 5 pts

```bash
useradd -m auditg
passwd auditg
# enter: cinder9
mkdir -p /projects/delta
chgrp deltaops /projects/delta
chmod 2770 /projects/delta
setfacl -m u:auditg:rwx /projects/delta
setfacl -m d:u:auditg:rwx /projects/delta
```

---

## Question 10 - User Umask (clientvm) - 5 pts

```bash
vim /home/pavel/.bashrc
umask 027
:wq
```

---

## Question 11 - At Job (clientvm) - 5 pts

```bash
systemctl enable --now atd
runuser -l pavel -c 'cat <<"EOF" | at now + 2 minutes
echo Delta queued >> /home/pavel/at-g.log
EOF'
atq
```

---

## Question 12 - Chrony Client (clientvm) - 5 pts

```bash
vim /etc/chrony.conf
# Comment any existing pool or server lines and add:
server servervm iburst
:wq
systemctl enable --now chronyd
```

---

## Question 13 - Direct NFS Mount (clientvm) - 4 pts

```bash
mkdir -p /mnt/delta-home
vim /etc/fstab
servervm:/exports/delta-home /mnt/delta-home nfs defaults 0 0
:wq
mount -a
```

---

## Question 14 - SSH Key And Secure Copy (servervm) - 4 pts

```bash
# On both systems
useradd -m copyg
passwd copyg
# enter: cinder9
runuser -l copyg -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519"
runuser -l copyg -c "ssh-copy-id -o StrictHostKeyChecking=no copyg@192.168.122.3"
runuser -l copyg -c "scp -o StrictHostKeyChecking=no /home/copyg/payload.txt copyg@192.168.122.3:/home/copyg/inbox/"
```

---

## Question 15 - Find And Copy (clientvm) - 4 pts

```bash
mkdir -p /root/trackerg-files
find /opt/exam-g/find -user trackerg -mtime -1 -type f -exec cp --parents {} /root/trackerg-files \;
```

---

## Question 16 - Grep Filter (clientvm) - 4 pts

```bash
grep ember /usr/share/dict/words > /root/ember-lines
```

---

## Question 17 - Archive (clientvm) - 4 pts

```bash
tar -cjf /root/etc-g.tar.bz2 /etc
```

---

## Question 18 - Persistent Journal (clientvm) - 4 pts

```bash
mkdir -p /var/log/journal
vim /etc/systemd/journald.conf
# Set: Storage=persistent
:wq
systemctl restart systemd-journald
```

---

## Question 19 - Process Renice And Kill (clientvm) - 4 pts

```bash
kill "$(cat /home/workerg/cpu.pid)"
renice 10 -p "$(cat /home/workerg/sleep.pid)"
```

---

## Question 20 - Swap Space (clientvm) - 4 pts

```bash
fdisk /dev/sdb
# g
# n
# <Enter>
# <Enter>
# +736M
# t
# 19
# w
mkswap /dev/sdb1
vim /etc/fstab
blkid /dev/sdb1
vim /etc/fstab
# Add the swap entry with the UUID reported above
:wq
:wq
swapon -a
```

---

## Question 21 - Create And Mount LV (clientvm) - 4 pts

```bash
fdisk /dev/sdc
# g
# n
# <Enter>
# <Enter>
# +700M
# t
# 31
# w
pvcreate /dev/sdc1
vgcreate -s 16M deltavg /dev/sdc1
lvcreate -n deltalv -l 40 deltavg
mkfs.ext4 /dev/deltavg/deltalv
mkdir -p /mnt/deltalv
vim /etc/fstab
blkid /dev/deltavg/deltalv
vim /etc/fstab
# Add the ext4 mount entry with the UUID reported above
:wq
:wq
mount -a
```

---

## Question 22 - Rootless Container Autostart (clientvm) - 4 pts

```bash
runuser -l solg -c "cd /opt/rhcsa/workspaces/exam-g && podman build -t localhost/delta-web:latest ."
runuser -l solg -c "podman run -d --name pdfg -v /opt/ing:/data/input:Z -v /opt/outg:/data/output:Z localhost/delta-web:latest"
runuser -l solg -c "mkdir -p ~/.config/systemd/user"
runuser -l solg -c "cd ~/.config/systemd/user && podman generate systemd --name pdfg --files --new"
runuser -l solg -c "systemctl --user daemon-reload"
runuser -l solg -c "systemctl --user enable --now container-pdfg.service"
loginctl enable-linger solg
```

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.deltaforge.lab'
grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192'
curl -fsS http://localhost:8086 >/dev/null && semanage port -l | grep -Eq '^http_port_t\b.*\b8086\b'
atq | grep -q pavel
findmnt -no TARGET,SOURCE,FSTYPE /mnt/deltalv | grep -Eq '^/mnt/deltalv /dev/mapper/deltavg-deltalv ext4$'
runuser -l solg -c 'systemctl --user is-enabled container-pdfg.service' | grep -qx enabled && runuser -l solg -c 'systemctl --user is-active container-pdfg.service' | grep -qx active && loginctl show-user solg | grep -Eq '^Linger=yes$'
```
