# Mock Exam B: CoreMesh Service Review

## Exam Solution
### Overview
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
nmcli connection show "$CONN"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.27/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.coremesh.lab
```

---

### Question 02 - Host Entry
**System:** clientvm

#### Command Flow
```bash
vim /etc/hosts
192.168.122.3 registry.coremesh.lab
```

---

### Question 03 - Client Repositories
**System:** clientvm

#### Command Flow
```bash
vim /etc/yum.repos.d/coremesh.repo
[coremesh-baseos]
name=CoreMesh BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[coremesh-appstream]
name=CoreMesh AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
```

---

### Question 04 - Server Repositories
**System:** servervm

#### Command Flow
```bash
# Run on servervm
vim /etc/yum.repos.d/coremesh.repo
[coremesh-baseos]
name=CoreMesh BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[coremesh-appstream]
name=CoreMesh AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
```

---

### Question 05 - Apache Firewall SELinux
**System:** clientvm

#### Command Flow
```bash
vim /etc/httpd/conf/httpd.conf
Listen 8383
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8383/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8383
systemctl restart httpd
```

---

### Question 06 - Users And Group
**System:** clientvm

#### Command Flow
```bash
groupadd platformb
useradd -m mira
useradd -m jonas
useradd -m -s /sbin/nologin noel
usermod -aG platformb mira
usermod -aG platformb jonas
```

---

### Question 07 - User Passwords
**System:** clientvm

#### Command Flow
```bash
passwd mira
# enter: cinder9
passwd jonas
# enter: cinder9
passwd noel
# enter: cinder9
```

---

### Question 08 - Delegated Sudo
**System:** clientvm

#### Command Flow
```bash
visudo -f /etc/sudoers.d/platformb
%platformb ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/mira-systemctl
mira ALL=(root) NOPASSWD: /usr/bin/systemctl restart httpd
```

---

### Question 09 - Setgid Directory
**System:** clientvm

#### Command Flow
```bash
mkdir -p /srv/platformb
chgrp platformb /srv/platformb
chmod 2770 /srv/platformb
```

---

### Question 10 - Cron Logger
**System:** clientvm

#### Command Flow
```bash
crontab -e -u mira
* * * * * logger "CoreMesh exam"
```

---

### Question 11 - Chrony Client
**System:** clientvm

#### Command Flow
```bash
vim /etc/chrony.conf
server servervm iburst
# remove any other server or pool lines
systemctl enable --now chronyd
```

---

### Question 12 - Autofs Map
**System:** clientvm

#### Command Flow
```bash
useradd -m meshremote
passwd meshremote
# enter: cinder9
vim /etc/auto.meshb
meshremote -rw,sync servervm:/exports/meshb
vim /etc/auto.master.d/meshb.autofs
/meshb /etc/auto.meshb
systemctl enable --now autofs
```

---

### Question 13 - Fixed UID User
**System:** clientvm

#### Command Flow
```bash
useradd -u 4421 cato421
passwd cato421
# enter: cinder9
```

---

### Question 14 - Find And Copy
**System:** clientvm

#### Command Flow
```bash
find /opt/exam-b/find -type f -user mira -mtime -1 -exec cp --parents {} /root/mira-files \;
```

---

### Question 15 - Grep Filter
**System:** clientvm

#### Command Flow
```bash
grep proto /usr/share/dict/words > /root/proto-lines
```

---

### Question 16 - Archive
**System:** clientvm

#### Command Flow
```bash
tar -cjf /root/usr-local-b.tar.bz2 /usr/local
```

---

### Question 17 - Unit Status Script
**System:** clientvm

#### Command Flow
```bash
vim /usr/local/bin/corecheck
#!/usr/bin/env bash
while read -r unit; do
  systemctl is-active "$unit" >> /root/coremesh-units.txt
done < /usr/local/share/exam-b/units.lst
chmod 755 /usr/local/bin/corecheck
/usr/local/bin/corecheck
```

---

### Question 18 - Swap Space
**System:** clientvm

#### Command Flow
```bash
fdisk /dev/sdb
# create a 600M GPT partition and set the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid-of-sdb1> swap swap defaults 0 0
```

---

### Question 19 - Resize Existing LV
**System:** clientvm

#### Command Flow
```bash
lvextend -L 300M /dev/reviewvgb/reviewb
resize2fs /dev/reviewvgb/reviewb
```

---

### Question 20 - Tuned Profile
**System:** clientvm

#### Command Flow
```bash
tuned-adm recommended
tuned-adm profile <recommended-profile>
```

---

### Question 21 - Rootless Container
**System:** clientvm

#### Command Flow
```bash
su - lyrab
cd /opt/rhcsa/workspaces/exam-b
podman build -t localhost/coremesh-web:latest .
podman run -d --name pdfb -v /opt/inb:/data/input:Z -v /opt/outb:/data/output:Z localhost/coremesh-web:latest
exit
```

---

### Question 22 - Container Autostart
**System:** clientvm

#### Command Flow
```bash
su - lyrab
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name pdfb --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-pdfb.service
exit
loginctl enable-linger lyrab
```
