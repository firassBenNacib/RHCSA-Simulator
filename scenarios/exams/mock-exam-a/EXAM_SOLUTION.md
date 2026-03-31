# Mock Exam A: OpsEdge Integrated Review - Exam Solution
Scenario ID: mock-exam-a
Mode: Exam
Time limit: 150 minutes
Objectives: boot-and-recovery, networking-and-firewall, storage-lvm, containers

A 22 task RHCSA style mock exam for RHEL 9 with recovery, repositories, SELinux, storage, and rootless containers.

General notes
- Unless a task states otherwise, make all changes persistent across reboots.
- Use the exact scenario variables shown in each question.
- Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Root Recovery (clientvm)
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

## Question 02 - Client Network (clientvm)
```bash
nmcli connection show
nmcli connection modify "<active-connection>" ipv4.addresses 192.168.122.26/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "<active-connection>"
nmcli connection up "<active-connection>"
hostnamectl set-hostname clientvm.opsedge.lab
```

## Question 03 - Static Host Entry (clientvm)
```bash
vim /etc/hosts
192.168.122.3 api.opsedge.lab
```

## Question 04 - Client Repositories (clientvm)
```bash
vim /etc/yum.repos.d/opsa.repo
[opsa-baseos]
name=OpsA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[opsa-appstream]
name=OpsA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
```

## Question 05 - Server Repositories (servervm)
```bash
ssh admin@servervm
sudo -i
vim /etc/yum.repos.d/opsa.repo
[opsa-baseos]
name=OpsA BaseOS
baseurl=http://servervm/repo/BaseOS/
enabled=1
gpgcheck=0

[opsa-appstream]
name=OpsA AppStream
baseurl=http://servervm/repo/AppStream/
enabled=1
gpgcheck=0
dnf clean all
exit
exit
```

## Question 06 - Apache SELinux Port (clientvm)
```bash
vim /etc/httpd/conf/httpd.conf
Listen 8282
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8282/tcp
firewall-cmd --reload
semanage port -a -t http_port_t -p tcp 8282
systemctl restart httpd
```

## Question 07 - Users And Group (clientvm)
```bash
groupadd sysopsa
useradd -m violet
useradd -m amber
useradd -m -s /sbin/nologin frost
usermod -aG sysopsa violet
usermod -aG sysopsa amber
```

## Question 08 - User Passwords (clientvm)
```bash
passwd violet
# enter: redhat
passwd amber
# enter: redhat
passwd frost
# enter: redhat
```

## Question 09 - Delegated Sudo (clientvm)
```bash
visudo -f /etc/sudoers.d/sysopsa
%sysopsa ALL=(root) /usr/sbin/useradd
visudo -f /etc/sudoers.d/violet-passwd
violet ALL=(root) NOPASSWD: /usr/bin/passwd
```

## Question 10 - Setgid Directory (clientvm)
```bash
mkdir -p /srv/sysopsa
chgrp sysopsa /srv/sysopsa
chmod 2770 /srv/sysopsa
```

## Question 11 - Cron Logger (clientvm)
```bash
crontab -e -u amber
*/2 * * * * logger "OpsEdge tick"
```

## Question 12 - Chrony Client (clientvm)
```bash
vim /etc/chrony.conf
server servervm iburst
# remove any other server or pool lines
systemctl enable --now chronyd
```

## Question 13 - Autofs Map (clientvm)
```bash
useradd -m netopsa
passwd netopsa
# enter: redhat
vim /etc/auto.opsa
netopsa -rw,sync servervm:/exports/researcha
vim /etc/auto.master.d/opsa.autofs
/researcha /etc/auto.opsa
systemctl enable --now autofs
```

## Question 14 - Fixed UID User (clientvm)
```bash
useradd -u 4420 ash420
passwd ash420
# enter: redhat
```

## Question 15 - Find And Copy (clientvm)
```bash
find /opt/exam-a/find -type f -user amber -mtime -1 -exec cp --parents {} /root/amber-files \;
```

## Question 16 - Grep Filter (clientvm)
```bash
grep delta /usr/share/dict/words > /root/delta-lines
```

## Question 17 - Archive (clientvm)
```bash
tar -cjf /root/etc-opsa.tar.bz2 /etc
```

## Question 18 - Service Audit Script (clientvm)
```bash
vim /usr/local/bin/opsa-report
#!/usr/bin/env bash
while read -r svc; do
  systemctl is-active "$svc" >> /root/opsa-services.txt
done < /usr/local/share/exam-a/services.lst
chmod 755 /usr/local/bin/opsa-report
/usr/local/bin/opsa-report
```

## Question 19 - Swap Space (clientvm)
```bash
fdisk /dev/sdb
# create a 512M GPT partition and set the type to Linux swap
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
blkid /dev/sdb1
vim /etc/fstab
UUID=<uuid-of-sdb1> swap swap defaults 0 0
```

## Question 20 - Resize Existing LV (clientvm)
```bash
lvextend -L 320M /dev/reviewvga/reviewa
resize2fs /dev/reviewvga/reviewa
```

## Question 21 - Rootless Container (clientvm)
```bash
su - oriona
cd /opt/rhcsa/workspaces/exam-a
podman build -t localhost/opsa-web:latest .
podman run -d --name pdfa -v /opt/ina:/data/input:Z -v /opt/outa:/data/output:Z localhost/opsa-web:latest
exit
```

## Question 22 - Container Autostart (clientvm)
```bash
su - oriona
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name pdfa --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-pdfa.service
exit
loginctl enable-linger oriona
```
