# Mock Exam E: HarborGrid Recovery Review

## Exam Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, software-scheduling-time, storage-lvm, selinux-and-default-perms |

A 22 question RHCSA style mock exam for RHEL 9 that adds pwquality, at scheduling, tuned, and an existing logical volume resize.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use the exact scenario variables shown in each question.
3. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 — Root Recovery
**System:** clientvm

#### Commands
```bash
# At the boot menu, edit the kernel line and append rd.break
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
# enter: redhat
touch /.autorelabel
exit
exit
```

---

## Question 02 — Client Network
**System:** clientvm

#### Commands
```bash
nmcli connection show
nmcli connection modify "<active-connection>" ipv4.addresses 192.168.122.37/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "<active-connection>"
nmcli connection up "<active-connection>"
hostnamectl set-hostname clientvm.harbor.lab
```

---

## Question 03 — Bootloader Kernel Argument
**System:** clientvm

#### Commands
```bash
grubby --update-kernel=ALL --args="audit=1"
grubby --info=ALL | grep -E "^kernel|^args"
```

---

## Question 04 — Client Repositories
**System:** clientvm

#### Commands
```bash
vim /etc/yum.repos.d/harbor.repo
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

## Question 05 — Server Repositories
**System:** servervm

#### Commands
```bash
# on servervm
vim /etc/yum.repos.d/harbor.repo
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

## Question 06 — Apache SELinux Port
**System:** clientvm

#### Commands
```bash
vim /etc/httpd/conf/httpd.conf
Listen 8181
semanage port -a -t http_port_t -p tcp 8181
firewall-cmd --permanent --add-port=8181/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

---

## Question 07 — Users And Group
**System:** clientvm

#### Commands
```bash
groupadd harborops
useradd -m lena
useradd -m ivor
useradd -m -s /sbin/nologin hush
usermod -aG harborops lena
usermod -aG harborops ivor
```

---

## Question 08 — User Passwords
**System:** clientvm

#### Commands
```bash
passwd lena
# enter: redhat
passwd ivor
# enter: redhat
passwd hush
# enter: redhat
```

---

## Question 09 — Delegated Sudo
**System:** clientvm

#### Commands
```bash
visudo -f /etc/sudoers.d/harborops
%harborops ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/lena-httpd
lena ALL=(root) NOPASSWD: /usr/bin/systemctl restart httpd
```

---

## Question 10 — Setgid Directory
**System:** clientvm

#### Commands
```bash
mkdir -p /srv/harbor
chown root:harborops /srv/harbor
chmod 2770 /srv/harbor
```

---

## Question 11 — Pwquality Policy
**System:** clientvm

#### Commands
```bash
mkdir -p /etc/security/pwquality.conf.d
vim /etc/security/pwquality.conf.d/exam-e.conf
minlen = 12
minclass = 3
```

---

## Question 12 — At Job
**System:** clientvm

#### Commands
```bash
systemctl enable --now atd
runuser -l ivor -c "echo "echo Harbor queued >> /home/ivor/at.log" | at now + 2 minutes"
atq
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
useradd -m harborremote
passwd harborremote
# enter: redhat
dnf -y install autofs
vim /etc/auto.master.d/harbor.autofs
/harbor/home /etc/auto.harbor
vim /etc/auto.harbor
harborremote -rw servervm:/exports/harborhome
systemctl enable --now autofs
```

---

## Question 15 — Fixed UID User
**System:** clientvm

#### Commands
```bash
useradd -u 4551 -m maple551
passwd maple551
# enter: redhat
```

---

## Question 16 — Find And Copy
**System:** clientvm

#### Commands
```bash
mkdir -p /root/scoutte-files
find /opt/exam-e/find -user scoutte -mtime -1 -type f -exec cp --parents {} /root/scoutte-files \;
```

---

## Question 17 — Grep Filter
**System:** clientvm

#### Commands
```bash
grep beacon /usr/share/dict/words > /root/beacon-lines
```

---

## Question 18 — Archive
**System:** clientvm

#### Commands
```bash
tar -cjf /root/var-tmp-harbor.tar.bz2 /var/tmp
```

---

## Question 19 — Shell Script
**System:** clientvm

#### Commands
```bash
vim /usr/local/bin/harbor-check
#!/bin/bash
> /root/harbor-services.txt
for svc in $(cat /usr/local/share/exam-e/services.lst); do
    systemctl is-active "$svc" >> /root/harbor-services.txt
done
chmod +x /usr/local/bin/harbor-check
/usr/local/bin/harbor-check
```

---

## Question 20 — Swap Space
**System:** clientvm

#### Commands
```bash
fdisk /dev/sdb
# create a 640 MiB partition and change the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid> swap swap defaults 0 0
```

---

## Question 21 — Resize Existing LV
**System:** clientvm

#### Commands
```bash
lvextend -L 360M /dev/reviewvge/reviewe
resize2fs /dev/reviewvge/reviewe
```

---

## Question 22 — Recommended Tuned Profile
**System:** clientvm

#### Commands
```bash
tuned-adm recommended
tuned-adm profile <recommended-profile>
```

---

### Verification
```bash
getent hosts registry.harbor.lab
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
atq
findmnt /mnt/reviewe
tuned-adm active
```
