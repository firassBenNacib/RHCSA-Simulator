# Mock Exam E: HarborGrid Recovery Review

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-e` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, software-scheduling-time, storage-lvm, selinux-and-default-perms |

A 22 question RHCSA style mock exam for RHEL 9 that adds pwquality, at scheduling, tuned, and an existing logical volume resize.

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
nmcli connection show "$CONN"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.37/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
hostnamectl set-hostname clientvm.harbor.lab
```

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
grubby --info=ALL | grep -E "^kernel|^args"
```

---

## Question 04 - Client Repositories (clientvm) - 5 pts

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

## Question 05 - Server Repositories (servervm) - 5 pts

```bash
# Run on servervm
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

## Question 06 - Apache SELinux Port (clientvm) - 5 pts

```bash
vim /etc/httpd/conf/httpd.conf
Listen 8181
semanage port -a -t http_port_t -p tcp 8181
firewall-cmd --permanent --add-port=8181/tcp
firewall-cmd --reload
systemctl enable --now httpd
```

---

## Question 07 - Users And Group (clientvm) - 5 pts

```bash
groupadd harborops
useradd -m lena
useradd -m ivor
useradd -m -s /sbin/nologin hush
usermod -aG harborops lena
usermod -aG harborops ivor
```

---

## Question 08 - User Passwords (clientvm) - 5 pts

```bash
passwd lena
# enter: cinder9
passwd ivor
# enter: cinder9
passwd hush
# enter: cinder9
```

---

## Question 09 - Delegated Sudo (clientvm) - 5 pts

```bash
visudo -f /etc/sudoers.d/harborops
%harborops ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/lena-httpd
lena ALL=(root) NOPASSWD: /usr/bin/systemctl restart httpd
```

---

## Question 10 - Setgid Directory (clientvm) - 5 pts

```bash
mkdir -p /srv/harbor
chown root:harborops /srv/harbor
chmod 2770 /srv/harbor
```

---

## Question 11 - Pwquality Policy (clientvm) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
vim /etc/security/pwquality.conf.d/exam-e.conf
minlen = 12
minclass = 3
```

---

## Question 12 - At Job (clientvm) - 5 pts

```bash
systemctl enable --now atd
runuser -l ivor -c 'cat <<"EOF" | at now + 2 minutes
echo Harbor queued >> /home/ivor/at.log
EOF'
atq
```

---

## Question 13 - Chrony Client (clientvm) - 4 pts

```bash
vim /etc/chrony.conf
server servervm iburst
systemctl enable --now chronyd
```

---

## Question 14 - Autofs Map (clientvm) - 4 pts

```bash
useradd -m harborremote
passwd harborremote
# enter: cinder9
dnf -y install autofs
vim /etc/auto.master.d/harbor.autofs
/harbor/home /etc/auto.harbor
vim /etc/auto.harbor
harborremote -rw servervm:/exports/harborhome
systemctl enable --now autofs
```

---

## Question 15 - Fixed UID User (clientvm) - 4 pts

```bash
useradd -u 4551 -m maple551
passwd maple551
# enter: cinder9
```

---

## Question 16 - Find And Copy (clientvm) - 4 pts

```bash
mkdir -p /root/scoutte-files
find /opt/exam-e/find -user scoutte -mtime -1 -type f -exec cp --parents {} /root/scoutte-files \;
```

---

## Question 17 - Grep Filter (clientvm) - 4 pts

```bash
grep beacon /usr/share/dict/words > /root/beacon-lines
```

---

## Question 18 - Archive (clientvm) - 4 pts

```bash
tar -cjf /root/var-tmp-harbor.tar.bz2 /var/tmp
```

---

## Question 19 - Shell Script (clientvm) - 4 pts

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

## Question 20 - Swap Space (clientvm) - 4 pts

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

## Question 21 - Resize Existing LV (clientvm) - 4 pts

```bash
lvextend -L 360M /dev/reviewvge/reviewe
resize2fs /dev/reviewvge/reviewe
```

---

## Question 22 - Recommended Tuned Profile (clientvm) - 4 pts

```bash
tuned-adm recommended
tuned-adm profile <recommended-profile>
```

---

## Verification
```bash
getent hosts registry.harbor.lab | grep -Fq '192.168.122.3'
grep -R -Eq '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*12[[:space:]]*$' /etc/security/pwquality.conf.d && grep -R -Eq '^[[:space:]]*minclass[[:space:]]*=[[:space:]]*3[[:space:]]*$' /etc/security/pwquality.conf.d
atq | grep -q ivor
lvs --noheadings -o lv_name,vg_name,lv_size --units m --nosuffix | awk '$1=="reviewe" && $2=="reviewvge" && $3>=359 && $3<=361{f=1} END{exit !f}' && findmnt -no TARGET /mnt/reviewe | grep -qx /mnt/reviewe
rec="$(tuned-adm recommended | awk '{print $1}')"; act="$(tuned-adm active | sed -E 's/.*: ([^ ]+).*/\1/')"; test -n "$rec" && test "$act" = "$rec"
```
