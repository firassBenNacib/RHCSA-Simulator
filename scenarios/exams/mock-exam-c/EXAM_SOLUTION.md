# Mock Exam C: NorthStar Recovery Review

## Exam Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-c` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, selinux-and-default-perms, storage-lvm, containers |

A third 22 task RHCSA style mock exam with another variable set and recovery workflow.

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

### Question 01 - Root Recovery
**System:** clientvm

#### Command Flow
```bash
# At the boot menu, edit the selected kernel entry.
# Append rw init=/bin/bash to the linux line and boot with Ctrl+x.
passwd root
# enter: cinder9
touch /.autorelabel
exec /sbin/init
```

---

### Question 02 - Client Network
**System:** clientvm

#### Command Flow
```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection show "$CONN"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.28/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.northstar.lab
```

---

### Question 03 - Bootloader Kernel Argument
**System:** clientvm

#### Command Flow
```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
grubby --info=ALL | grep -E "^kernel|^args"
```

---

### Question 04 - Client Repositories
**System:** clientvm

#### Command Flow
```bash
vim /etc/yum.repos.d/northstar.repo
[northstar-baseos]
name=NorthStar BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[northstar-appstream]
name=NorthStar AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
```

---

### Question 05 - Server Repositories
**System:** servervm

#### Command Flow
```bash
# Run on servervm
vim /etc/yum.repos.d/northstar.repo
[northstar-baseos]
name=NorthStar BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[northstar-appstream]
name=NorthStar AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
```

---

### Question 06 - Apache Firewall SELinux
**System:** clientvm

#### Command Flow
```bash
vim /etc/httpd/conf/httpd.conf
Listen 8484
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8484/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8484
systemctl restart httpd
```

---

### Question 07 - Users And Group
**System:** clientvm

#### Command Flow
```bash
groupadd infrac
useradd -m talia
useradd -m ren
useradd -m -s /sbin/nologin sage
usermod -aG infrac talia
usermod -aG infrac ren
```

---

### Question 08 - User Passwords
**System:** clientvm

#### Command Flow
```bash
passwd talia
# enter: cinder9
passwd ren
# enter: cinder9
passwd sage
# enter: cinder9
```

---

### Question 09 - Delegated Sudo
**System:** clientvm

#### Command Flow
```bash
visudo -f /etc/sudoers.d/infrac
%infrac ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/talia-passwd
talia ALL=(root) NOPASSWD: /usr/bin/passwd
```

---

### Question 10 - Setgid Directory
**System:** clientvm

#### Command Flow
```bash
mkdir -p /srv/infrac
chgrp infrac /srv/infrac
chmod 2770 /srv/infrac
```

---

### Question 11 - Cron Logger
**System:** clientvm

#### Command Flow
```bash
crontab -e -u ren
*/5 * * * * logger "NorthStar exam"
```

---

### Question 12 - Chrony Client
**System:** clientvm

#### Command Flow
```bash
vim /etc/chrony.conf
server servervm iburst
# remove any other server or pool lines
systemctl enable --now chronyd
```

---

### Question 13 - Autofs Map
**System:** clientvm

#### Command Flow
```bash
useradd -m remote63
passwd remote63
# enter: cinder9
vim /etc/auto.bluec
remote63 -rw,sync servervm:/exports/bluec
vim /etc/auto.master.d/bluec.autofs
/bluec /etc/auto.bluec
systemctl enable --now autofs
```

---

### Question 14 - Fixed UID User
**System:** clientvm

#### Command Flow
```bash
useradd -u 4431 kian431
passwd kian431
# enter: cinder9
```

---

### Question 15 - Find And Copy
**System:** clientvm

#### Command Flow
```bash
find /opt/exam-c/find -type f -user ren -mtime -1 -exec cp --parents {} /root/ren-files \;
```

---

### Question 16 - Grep Filter
**System:** clientvm

#### Command Flow
```bash
grep orbit /usr/share/dict/words > /root/orbit-lines
```

---

### Question 17 - Archive
**System:** clientvm

#### Command Flow
```bash
tar -cjf /root/etc-c.tar.bz2 /etc
```

---

### Question 18 - Service Status Script
**System:** clientvm

#### Command Flow
```bash
vim /usr/local/bin/northcheck
#!/usr/bin/env bash
while read -r svc; do
  systemctl is-active "$svc" >> /root/north-services.txt
done < /usr/local/share/exam-c/check.lst
chmod 755 /usr/local/bin/northcheck
/usr/local/bin/northcheck
```

---

### Question 19 - Swap Space
**System:** clientvm

#### Command Flow
```bash
fdisk /dev/sdb
# create a 700M GPT partition and set the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid-of-sdb1> swap swap defaults 0 0
```

---

### Question 20 - Resize Existing LV
**System:** clientvm

#### Command Flow
```bash
lvextend -L 340M /dev/reviewvgc/reviewc
resize2fs /dev/reviewvgc/reviewc
```

---

### Question 21 - Rootless Container
**System:** clientvm

#### Command Flow
```bash
su - eirac
cd /opt/rhcsa/workspaces/exam-c
podman build -t localhost/northstar-web:latest .
podman run -d --name pdfc -v /opt/inc:/data/input:Z -v /opt/outc:/data/output:Z localhost/northstar-web:latest
exit
```

---

### Question 22 - Container Autostart
**System:** clientvm

#### Command Flow
```bash
su - eirac
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name pdfc --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-pdfc.service
exit
loginctl enable-linger eirac
```
