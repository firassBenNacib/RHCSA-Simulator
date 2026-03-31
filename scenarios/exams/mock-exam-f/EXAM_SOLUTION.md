# Mock Exam F: AuroraPath Access Review

## Exam Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-f` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, storage-lvm, users-sudo-ssh, containers |

A 22 question RHCSA style mock exam for RHEL 9 that adds key based SSH access, a restrictive rich rule, an alternate umask, and another create mount container build workflow.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use the exact scenario variables shown in each question.
3. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 — Client Network
**System:** clientvm

#### Commands
```bash
nmcli connection show
nmcli connection modify "<active-connection>" ipv4.addresses 192.168.122.38/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "<active-connection>"
nmcli connection up "<active-connection>"
hostnamectl set-hostname clientvm.aurora.lab
```

---

## Question 02 — Static Host Entry
**System:** clientvm

#### Commands
```bash
vim /etc/hosts
192.168.122.3 db.aurora.lab
```

---

## Question 03 — Client Repositories
**System:** clientvm

#### Commands
```bash
vim /etc/yum.repos.d/aurora.repo
[BaseOS]
name=BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[AppStream]
name=AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
```

---

## Question 04 — Server Repositories
**System:** servervm

#### Commands
```bash
# on servervm
vim /etc/yum.repos.d/aurora.repo
[BaseOS]
name=BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[AppStream]
name=AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
```

---

## Question 05 — Apache Custom Docroot
**System:** clientvm

#### Commands
```bash
vim /etc/httpd/conf.d/aurora.conf
<VirtualHost *:9090>
    DocumentRoot /srv/aurora-web
    <Directory /srv/aurora-web>
        Require all granted
    </Directory>
</VirtualHost>
semanage fcontext -a -t httpd_sys_content_t "/srv/aurora-web(/.*)?"
restorecon -Rv /srv/aurora-web
semanage port -a -t http_port_t -p tcp 9090
firewall-cmd --permanent --add-port=9090/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

---

## Question 06 — Users And Group
**System:** clientvm

#### Commands
```bash
groupadd auroraops
useradd -m elio
useradd -m risa
useradd -m -s /sbin/nologin nox
usermod -aG auroraops elio
usermod -aG auroraops risa
```

---

## Question 07 — User Passwords
**System:** clientvm

#### Commands
```bash
passwd elio
# enter: redhat
passwd risa
# enter: redhat
passwd nox
# enter: redhat
```

---

## Question 08 — Delegated Sudo
**System:** clientvm

#### Commands
```bash
visudo -f /etc/sudoers.d/auroraops
%auroraops ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/elio-passwd
elio ALL=(root) NOPASSWD: /usr/bin/passwd
```

---

## Question 09 — Shared Directory With Default ACL
**System:** clientvm

#### Commands
```bash
useradd -m auditf
passwd auditf
# enter: redhat
mkdir -p /data/aurora
chown root:auroraops /data/aurora
chmod 2770 /data/aurora
setfacl -m d:u:auditf:rwx /data/aurora
```

---

## Question 10 — User Umask
**System:** clientvm

#### Commands
```bash
vim /home/risa/.bashrc
umask 077
chown risa:risa /home/risa/.bashrc
```

---

## Question 11 — SSH Key Authentication
**System:** clientvm + servervm

#### Commands
```bash
useradd -m opsf
passwd opsf
# enter: redhat
# on servervm
useradd -m backupf
passwd backupf
# enter: redhat
runuser -l opsf -c "ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa"
runuser -l opsf -c "ssh-copy-id backupf@servervm"
```

---

## Question 12 — Firewalld Rich Rule
**System:** clientvm

#### Commands
```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
firewall-cmd --list-rich-rules
```

---

## Question 13 — Chrony Client
**System:** clientvm

#### Commands
```bash
vim /etc/chrony.conf
server servervm iburst
systemctl enable --now chronyd
```

---

## Question 14 — Autofs Map
**System:** clientvm

#### Commands
```bash
useradd -m aurorarem
passwd aurorarem
# enter: redhat
dnf -y install autofs
vim /etc/auto.master.d/aurora.autofs
/aurora/home /etc/auto.aurora
vim /etc/auto.aurora
aurorarem -rw servervm:/exports/aurorahome
systemctl enable --now autofs
```

---

## Question 15 — Fixed UID User
**System:** clientvm

#### Commands
```bash
useradd -u 4560 -m pine560
passwd pine560
# enter: redhat
```

---

## Question 16 — Find And Copy
**System:** clientvm

#### Commands
```bash
mkdir -p /root/seekerf-files
find /opt/exam-f/find -user seekerf -mtime -1 -type f -exec cp --parents {} /root/seekerf-files \;
```

---

## Question 17 — Grep Filter
**System:** clientvm

#### Commands
```bash
grep comet /usr/share/dict/words > /root/comet-lines
```

---

## Question 18 — Archive
**System:** clientvm

#### Commands
```bash
tar -czf /root/usr-local-f.tar.gz /usr/local
```

---

## Question 19 — Shell Script
**System:** clientvm

#### Commands
```bash
vim /usr/local/bin/aurora-report
#!/bin/bash
> /root/aurora-units.txt
for unit in $(cat /usr/local/share/exam-f/units.lst); do
    systemctl is-active "$unit" >> /root/aurora-units.txt
done
chmod +x /usr/local/bin/aurora-report
/usr/local/bin/aurora-report
```

---

## Question 20 — Swap Space
**System:** clientvm

#### Commands
```bash
fdisk /dev/sdb
# create a 704 MiB partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid> swap swap defaults 0 0
```

---

## Question 21 — Create And Mount LV
**System:** clientvm

#### Commands
```bash
fdisk /dev/sdc
# create one Linux LVM partition that uses the disk
partprobe /dev/sdc
pvcreate /dev/sdc1
vgcreate -s 8M auroravg /dev/sdc1
lvcreate -n auroralv -l 50 auroravg
mkfs.xfs -f /dev/auroravg/auroralv
mkdir -p /mnt/auroralv
blkid /dev/auroravg/auroralv
vim /etc/fstab
UUID=<uuid> /mnt/auroralv xfs defaults 0 0
mount -a
```

---

## Question 22 — Rootless Container Autostart
**System:** clientvm

#### Commands
```bash
runuser -l solf -c "cd /opt/rhcsa/workspaces/exam-f && podman build -t localhost/aurora-web:latest ."
runuser -l solf -c "podman run -d --name pdff -v /opt/inf:/data/input:Z -v /opt/outf:/data/output:Z localhost/aurora-web:latest"
runuser -l solf -c "mkdir -p ~/.config/systemd/user"
runuser -l solf -c "cd ~/.config/systemd/user && podman generate systemd --name pdff --files --new"
runuser -l solf -c "systemctl --user daemon-reload"
runuser -l solf -c "systemctl --user enable --now container-pdff.service"
loginctl enable-linger solf
```

---

### Verification
```bash
getent hosts db.aurora.lab
firewall-cmd --list-rich-rules
runuser -l opsf -c "ssh -o StrictHostKeyChecking=no -o BatchMode=yes backupf@servervm true"
findmnt /mnt/auroralv
runuser -l solf -c "systemctl --user status container-pdff.service --no-pager"
```
