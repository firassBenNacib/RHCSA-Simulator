# Mock Exam G: DeltaForge Recovery Review

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
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.39/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
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
grep -q 'vault.deltaforge.lab' /etc/hosts || echo '192.168.122.3 vault.deltaforge.lab' >> /etc/hosts
```

---

## Question 05 - Direct NFS Mount (clientvm) - 5 pts

```bash
mkdir -p /mnt/delta-home
grep -q '/mnt/delta-home' /etc/fstab || echo 'servervm:/exports/delta-home /mnt/delta-home nfs defaults,_netdev 0 0' >> /etc/fstab
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
install -d -m 3770 -o root -g deltaops /projects/delta-drop
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
install -d -m 0755 -o copyg -g copyg /home/copyg/inbox
```

---

## Question 12 - SSH Key And Secure Copy (clientvm + servervm) - 5 pts

```bash
runuser -l copyg -c 'ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519'
runuser -l copyg -c 'ssh-copy-id copyg@servervm'
runuser -l copyg -c 'scp /opt/exam-g/copyg-payload.txt copyg@servervm:/home/copyg/inbox/payload.txt'
```

---

## Question 13 - At Job (clientvm) - 4 pts

```bash
runuser -l pavel -c 'echo "echo DeltaForge tick >> /root/delta-at.log" | at now + 2 minutes'
systemctl enable --now atd
```

---

## Question 14 - Per-User Login Message (clientvm) - 4 pts

```bash
echo 'echo DeltaForge access' >> /home/pavel/.bash_profile
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
hostnamectl --static | grep -qx 'clientvm.deltaforge.lab' && grep -Fqx '192.168.122.3 vault.deltaforge.lab' /etc/hosts && grubby --info=ALL | grep -Eq 'args=.*audit_backlog_limit=8192'
mount | grep -Eq 'servervm:/exports/delta-home on /mnt/delta-home type nfs' && getent group deltaops >/dev/null && id -nG pavel | tr ' ' '\n' | grep -qx deltaops && stat -c '%a %U:%G' /projects/delta-drop | grep -qx '3770 root:deltaops' && getent passwd auditg | awk -F: '{print $6":"$7}' | grep -qx ':/sbin/nologin'
chage -l pavel | grep -Eq 'Maximum.*45' && grep -Fqx 'umask 027' /home/pavel/.bash_profile && grep -Fqx 'echo DeltaForge access' /home/pavel/.bash_profile && atq | grep -q pavel
runuser -l copyg -c 'ssh -o BatchMode=yes copyg@servervm true' && ssh admin@servervm test -f /home/copyg/inbox/payload.txt
test -f /root/trackerg-files/opt/exam-g/find/a/file1.txt && grep -q 'ember' /root/ember-lines && test -f /root/etc-g.tar.bz2 && test -d /var/log/journal && ! ps -p "$(cat /home/workerg/cpu.pid)" >/dev/null 2>&1 && ps -o ni= -p "$(cat /home/workerg/sleep.pid)" | tr -d ' ' | grep -qx '10'
swapon --show=NAME --noheadings | grep -qx '/dev/sdb1' && findmnt -no TARGET,SOURCE,FSTYPE /mnt/deltalv | grep -Eq '^/mnt/deltalv /dev/mapper/deltavg-deltalv ext4$' && runuser -l solg -c 'systemctl --user is-enabled container-pdfg.service' | grep -qx enabled && runuser -l solg -c 'systemctl --user is-active container-pdfg.service' | grep -qx active && loginctl show-user solg | grep -Eq '^Linger=yes$'
```
