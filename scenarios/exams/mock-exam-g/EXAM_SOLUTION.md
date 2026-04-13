# Mock Exam G

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-g` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | boot-and-recovery, filesystems-and-autofs, users-sudo-ssh, storage-lvm, containers |

A 22 task RHCSA style mock exam combining recovery, NFS, sticky directories, SSH key transfer, process handling, and rootless containers.

### Systems
- clientvm
- servervm

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
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.39/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.deltaforge.lab
```

---

## Question 03 - Bootloader Kernel Argument (clientvm) - 5 pts

```bash
grubby --update-kernel=ALL --args="audit_backlog_limit=8192"
```

---

## Question 04 - Host Entry (clientvm) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 vault.deltaforge.lab
```

---

## Question 05 - Direct NFS Mount (clientvm) - 5 pts

```bash
mkdir -p /mnt/delta-home
vim /etc/fstab
servervm:/exports/delta-home /mnt/delta-home nfs defaults,_netdev 0 0
mount -a
```

---

## Question 06 - Ops User And Group (clientvm) - 5 pts

```bash
groupadd deltaops
useradd -G deltaops pavel
echo cinder9 | passwd --stdin pavel
```

---

## Question 07 - Sticky Shared Directory (clientvm) - 5 pts

```bash
chmod 770 /projects/delta-drop
chmod g+s,+t /projects/delta-drop
```

---

## Question 08 - No-Home Audit User (clientvm) - 5 pts

```bash
useradd -M -s /sbin/nologin auditg
```

---

## Question 09 - Password Aging (clientvm) - 5 pts

```bash
chage -M 45 -m 5 -W 7 pavel
```

---

## Question 10 - User Umask (clientvm) - 5 pts

```bash
echo 'umask 027' >> /home/pavel/.bash_profile
```

---

## Question 11 - Copy User On Both Systems (clientvm) - 5 pts

```bash
useradd copyg
echo cinder9 | passwd --stdin copyg
# Run on servervm
useradd copyg
echo cinder9 | passwd --stdin copyg
mkdir -p /home/copyg/inbox
chown copyg:copyg /home/copyg/inbox
chmod 0755 /home/copyg/inbox
```

---

## Question 12 - SSH Key And Secure Copy (clientvm + servervm) - 5 pts

```bash
su - copyg
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id copyg@servervm
scp /opt/exam-g/copyg-payload.txt copyg@servervm:/home/copyg/inbox/payload.txt
```

---

## Question 13 - At Job (clientvm) - 4 pts

```bash
su - pavel
echo "echo exam-g tick >> /root/exam-g-at.log" | at now + 2 minutes
systemctl enable --now atd
```

---

## Question 14 - Per-User Login Message (clientvm) - 4 pts

```bash
echo 'echo exam-g access' >> /home/pavel/.bash_profile
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
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 737MiB
partprobe /dev/sdb
mkswap /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
swapon -a
```

---

## Question 21 - Create And Mount LV (clientvm) - 4 pts

```bash
parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 701MiB set 1 lvm on
partprobe /dev/sdc
pvcreate /dev/sdc1
vgcreate -s 16M deltavg /dev/sdc1
lvcreate -n deltalv -l 40 deltavg
mkfs.ext4 /dev/deltavg/deltalv
mkdir -p /mnt/deltalv
uuid=$(blkid -s UUID -o value /dev/deltavg/deltalv)
echo "UUID=$uuid /mnt/deltalv ext4 defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 22 - Rootless Container Autostart (clientvm) - 4 pts

```bash
su - solg
cd /opt/rhcsa/workspaces/exam-g && podman build -t localhost/delta-web:latest .
podman run -d --name pdfg -v /opt/ing:/data/input:Z -v /opt/outg:/data/output:Z localhost/delta-web:latest
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user && podman generate systemd --name pdfg --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-pdfg.service
loginctl enable-linger solg
```
