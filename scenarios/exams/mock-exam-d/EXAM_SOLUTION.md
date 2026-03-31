# Mock Exam D: SummitLine Operations Review

## Exam Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-d` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, storage-lvm, users-sudo-ssh, containers |

A 22 question RHCSA style mock exam for RHEL 9 that adds default ACLs, umask tuning, password aging, and a full create mount storage task.

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

#### Command Flow
```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection show "$CONN"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.36/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.summit.lab
```

---

### Question 02 — Static Host Entry
**System:** clientvm

#### Command Flow
```bash
vim /etc/hosts
192.168.122.3 mirror.summit.lab
```

---

### Question 03 — Client Repositories
**System:** clientvm

#### Command Flow
```bash
vim /etc/yum.repos.d/summit.repo
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

### Question 04 — Server Repositories
**System:** servervm

#### Command Flow
```bash
# Run on servervm
# on servervm
vim /etc/yum.repos.d/summit.repo
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

### Question 05 — Apache Custom Docroot
**System:** clientvm

#### Command Flow
```bash
vim /etc/httpd/conf.d/summit.conf
<VirtualHost *:8085>
    DocumentRoot /srv/summit-web
    <Directory /srv/summit-web>
        Require all granted
    </Directory>
</VirtualHost>
semanage fcontext -a -t httpd_sys_content_t "/srv/summit-web(/.*)?"
restorecon -Rv /srv/summit-web
semanage port -a -t http_port_t -p tcp 8085
firewall-cmd --permanent --add-port=8085/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

---

### Question 06 — Users And Group
**System:** clientvm

#### Command Flow
```bash
groupadd summitops
useradd -m kara
useradd -m miles
useradd -m -s /sbin/nologin zero
usermod -aG summitops kara
usermod -aG summitops miles
```

---

### Question 07 — User Passwords
**System:** clientvm

#### Command Flow
```bash
passwd kara
# enter: redhat
passwd miles
# enter: redhat
passwd zero
# enter: redhat
```

---

### Question 08 — Delegated Sudo
**System:** clientvm

#### Command Flow
```bash
visudo -f /etc/sudoers.d/summitops
%summitops ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/kara-passwd
kara ALL=(root) NOPASSWD: /usr/bin/passwd
```

---

### Question 09 — Shared Directory With Default ACL
**System:** clientvm

#### Command Flow
```bash
useradd -m auditord
passwd auditord
# enter: redhat
mkdir -p /projects/summit
chown root:summitops /projects/summit
chmod 2770 /projects/summit
setfacl -m d:u:auditord:rwx /projects/summit
```

---

### Question 10 — User Umask
**System:** clientvm

#### Command Flow
```bash
vim /home/miles/.bashrc
umask 027
chown miles:miles /home/miles/.bashrc
```

---

### Question 11 — Password Aging Defaults
**System:** clientvm

#### Command Flow
```bash
vim /etc/login.defs
PASS_MAX_DAYS   45
PASS_MIN_DAYS   2
PASS_WARN_AGE   10
useradd -m trainee54
passwd trainee54
# enter: redhat
chage -l trainee54
```

---

### Question 12 — Cron Logger
**System:** clientvm

#### Command Flow
```bash
crontab -e -u miles
*/15 * * * * logger "Summit exam"
```

---

### Question 13 — Chrony Client
**System:** clientvm

#### Command Flow
```bash
vim /etc/chrony.conf
server servervm iburst
systemctl enable --now chronyd
```

---

### Question 14 — Autofs Map
**System:** clientvm

#### Command Flow
```bash
useradd -m summitremote
passwd summitremote
# enter: redhat
dnf -y install autofs
vim /etc/auto.master.d/summit.autofs
/summit-home /etc/auto.summit
vim /etc/auto.summit
summitremote -rw servervm:/exports/summit-home
systemctl enable --now autofs
```

---

### Question 15 — Fixed UID User
**System:** clientvm

#### Command Flow
```bash
useradd -u 4540 -m cedar540
passwd cedar540
# enter: redhat
```

---

### Question 16 — Find And Copy
**System:** clientvm

#### Command Flow
```bash
mkdir -p /root/miles-files
find /opt/exam-d/find -user foragerd -mtime -1 -type f -exec cp --parents {} /root/miles-files \;
```

---

### Question 17 — Grep Filter
**System:** clientvm

#### Command Flow
```bash
grep alpha /usr/share/dict/words > /root/alpha-lines
```

---

### Question 18 — Archive
**System:** clientvm

#### Command Flow
```bash
tar -czf /root/summit-etc.tar.gz /etc
```

---

### Question 19 — Shell Script
**System:** clientvm

#### Command Flow
```bash
vim /usr/local/bin/summit-scan
#!/bin/bash
> /root/summit-units.txt
for unit in $(cat /usr/local/share/exam-d/units.lst); do
    systemctl is-active "$unit" >> /root/summit-units.txt
done
chmod +x /usr/local/bin/summit-scan
/usr/local/bin/summit-scan
```

---

### Question 20 — Swap Space
**System:** clientvm

#### Command Flow
```bash
fdisk /dev/sdb
# create a 768 MiB partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid> swap swap defaults 0 0
```

---

### Question 21 — Create And Mount LV
**System:** clientvm

#### Command Flow
```bash
fdisk /dev/sdc
# create one Linux LVM partition that uses the disk
partprobe /dev/sdc
pvcreate /dev/sdc1
vgcreate -s 16M summitvg /dev/sdc1
lvcreate -n summitlv -l 40 summitvg
mkfs.ext4 /dev/summitvg/summitlv
mkdir -p /mnt/summitlv
blkid /dev/summitvg/summitlv
vim /etc/fstab
UUID=<uuid> /mnt/summitlv ext4 defaults 0 0
mount -a
```

---

### Question 22 — Rootless Container Autostart
**System:** clientvm

#### Command Flow
```bash
runuser -l neriad -c "cd /opt/rhcsa/workspaces/exam-d && podman build -t localhost/summit-web:latest ."
runuser -l neriad -c "podman run -d --name pdfd -v /opt/ind:/data/input:Z -v /opt/outd:/data/output:Z localhost/summit-web:latest"
runuser -l neriad -c "mkdir -p ~/.config/systemd/user"
runuser -l neriad -c "cd ~/.config/systemd/user && podman generate systemd --name pdfd --files --new"
runuser -l neriad -c "systemctl --user daemon-reload"
runuser -l neriad -c "systemctl --user enable --now container-pdfd.service"
loginctl enable-linger neriad
```

---

### Verification
```bash
getent hosts mirror.summit.lab
curl -s http://localhost:8085
getfacl /projects/summit
chage -l trainee54
findmnt /mnt/summitlv
runuser -l neriad -c "systemctl --user status container-pdfd.service --no-pager"
```
