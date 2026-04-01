# Mock Exam H: SilverPeak Services Review

## Exam Solution
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

### Question 01 - Client Network
**System:** clientvm

#### Command Flow
```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.47/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.silverpeak.lab
```

---

### Question 02 - Static Host Entry
**System:** clientvm

#### Command Flow
```bash
vim /etc/hosts
192.168.122.3 registry.silverpeak.lab
:wq
```

---

### Question 03 - Repositories On Both Systems
**System:** clientvm + servervm

#### Command Flow
```bash
# On clientvm
vim /etc/yum.repos.d/silver.repo
[silver-baseos]
name=Silver BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[silver-appstream]
name=Silver AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
:wq
dnf clean all
# On servervm
vim /etc/yum.repos.d/silver.repo
[silver-baseos]
name=Silver BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[silver-appstream]
name=Silver AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
:wq
dnf clean all
```

---

### Question 04 - Apache SELinux Port
**System:** clientvm

#### Command Flow
```bash
vim /etc/httpd/conf/httpd.conf
Listen 8181
:wq
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8181/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8181
systemctl restart httpd
```

---

### Question 05 - Users And Group
**System:** clientvm

#### Command Flow
```bash
groupadd silverops
useradd -m iris
useradd -m daren
useradd -m -s /sbin/nologin hush
usermod -aG silverops iris
usermod -aG silverops daren
```

---

### Question 06 - User Passwords
**System:** clientvm

#### Command Flow
```bash
passwd iris
# enter: cinder9
passwd daren
# enter: cinder9
passwd hush
# enter: cinder9
```

---

### Question 07 - Delegated Sudo
**System:** clientvm

#### Command Flow
```bash
visudo -f /etc/sudoers.d/silverops
%silverops ALL=(ALL) /usr/sbin/useradd
:wq
visudo -f /etc/sudoers.d/iris-passwd
iris ALL=(ALL) NOPASSWD: /usr/bin/passwd
:wq
```

---

### Question 08 - Setgid Directory
**System:** clientvm

#### Command Flow
```bash
mkdir -p /srv/silver
chgrp silverops /srv/silver
chmod 2770 /srv/silver
```

---

### Question 09 - Pwquality Policy
**System:** clientvm

#### Command Flow
```bash
mkdir -p /etc/security/pwquality.conf.d
vim /etc/security/pwquality.conf.d/silver.conf
minlen = 12
minclass = 3
:wq
```

---

### Question 10 - Per-User Password Aging
**System:** clientvm

#### Command Flow
```bash
useradd -m agingh
passwd agingh
# enter: cinder9
chage -M 30 -m 2 -W 7 agingh
chage -d 0 agingh
```

---

### Question 11 - Chrony Client
**System:** clientvm

#### Command Flow
```bash
vim /etc/chrony.conf
# Comment any existing pool or server lines and add:
server servervm iburst
:wq
systemctl enable --now chronyd
```

---

### Question 12 - Autofs Map
**System:** clientvm

#### Command Flow
```bash
useradd -m silverremote
passwd silverremote
# enter: cinder9
vim /etc/auto.silver
silverremote -rw servervm:/exports/silverhome
:wq
vim /etc/auto.master.d/silver.autofs
/silver/home /etc/auto.silver
:wq
systemctl enable --now autofs
```

---

### Question 13 - Firewalld Rich Rule
**System:** clientvm

#### Command Flow
```bash
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept"
firewall-cmd --reload
```

---

### Question 14 - Find And Copy
**System:** clientvm

#### Command Flow
```bash
mkdir -p /root/watcherh-files
find /opt/exam-h/find -user watcherh -mtime -1 -type f -exec cp --parents {} /root/watcherh-files \;
```

---

### Question 15 - Grep Filter
**System:** clientvm

#### Command Flow
```bash
grep silver /usr/share/dict/words > /root/silver-lines
```

---

### Question 16 - Archive
**System:** clientvm

#### Command Flow
```bash
tar -czf /root/usr-local-h.tar.gz /usr/local
```

---

### Question 17 - Swap Space
**System:** clientvm

#### Command Flow
```bash
fdisk /dev/sdb
# g
# n
# <Enter>
# <Enter>
# +672M
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

### Question 18 - Resize Existing LV
**System:** clientvm

#### Command Flow
```bash
lvextend -L 320M /dev/reviewvgh/reviewh
resize2fs /dev/reviewvgh/reviewh
```

---

### Question 19 - Boot Target And Services
**System:** clientvm

#### Command Flow
```bash
systemctl set-default multi-user.target
systemctl enable --now rsyslog
systemctl disable --now postfix
```

---

### Question 20 - Install And Remove Packages
**System:** clientvm

#### Command Flow
```bash
dnf install -y tree dos2unix
dnf remove -y dos2unix
rpm -q tree
```

---

### Question 21 - Inspect Container Image
**System:** clientvm

#### Command Flow
```bash
id inspecth || useradd -m inspecth
passwd inspecth
# enter: cinder9
runuser -l inspecth -c "podman load -i /opt/rhcsa/container-assets/rhcsa-httpd-base.tar"
runuser -l inspecth -c "podman image inspect localhost/rhcsa-httpd-base:latest --format {{.Config.WorkingDir}} > ~/workdir.txt"
```

---

### Question 22 - Recommended Tuned Profile
**System:** clientvm

#### Command Flow
```bash
tuned-adm profile $(tuned-adm recommend)
tuned-adm active
```
