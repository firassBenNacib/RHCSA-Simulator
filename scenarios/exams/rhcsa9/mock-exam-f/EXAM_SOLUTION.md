# Mock Exam F

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-f` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22 task RHCSA style mock exam centered on chrony, SSH hardening, account defaults, rsync, and storage administration.

### Systems
- client
- server

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (client) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.38/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.exam-f.lab
```

---

## Question 02 - Host Entry (client) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 db.exam-f.lab
```

---

## Question 03 - Chrony Server (server) - 5 pts

```bash
# Run on server
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.122.0/24
local stratum 10
EOF
systemctl enable --now chronyd
```

---

## Question 04 - Chrony Client (client) - 5 pts

```bash
cat > /etc/chrony.conf <<'EOF'
server server iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF
systemctl enable --now chronyd
```

---

## Question 05 - SSH Port (server) - 5 pts

```bash
# Run on server
python - <<'EOF'
from pathlib import Path
import re
p = Path('/etc/ssh/sshd_config')
text = p.read_text() if p.exists() else ''
for key in ['Port', 'PasswordAuthentication', 'PubkeyAuthentication']:
    text = re.sub(rf'^\\s*#?{key}\\s+.*$', '', text, flags=re.M)
text += '\nPort 22\nPort 2222\nPasswordAuthentication yes\nPubkeyAuthentication yes\n'
p.write_text(text)
EOF
semanage port -a -t ssh_port_t -p tcp 2222 || semanage port -m -t ssh_port_t -p tcp 2222
sshd -t
systemctl reload sshd || systemctl restart sshd
```

---

## Question 06 - Rich Rule (server) - 5 pts

```bash
# Run on server
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 07 - Useradd Defaults (client) - 5 pts

```bash
useradd -D -f 14
```

---

## Question 08 - No-Home UID User (client) - 5 pts

```bash
id pine560 >/dev/null 2>&1 || useradd -M -u 4560 -s /sbin/nologin pine560
usermod -u 4560 -s /sbin/nologin pine560
rm -rf /home/pine560
echo cinder9 | passwd --stdin pine560
```

---

## Question 09 - Admin User (client) - 5 pts

```bash
id elio >/dev/null 2>&1 || useradd -m elio
echo cinder9 | passwd --stdin elio
```

---

## Question 10 - Delegated Sudo (client) - 5 pts

```bash
visudo -f /etc/sudoers.d/elio-firewalld
elio ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld
```

---

## Question 11 - SSH Key Generation (client) - 5 pts

```bash
install -d -m 700 -o elio -g elio /home/elio/.ssh
cat > /home/elio/.ssh/id_ed25519 <<'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAuG+yT39D4/Azac0uRQnH8KcYvvcUmnuHAoPQHJKU4zwAAAKA2lzCKNpcw
igAAAAtzc2gtZWQyNTUxOQAAACAuG+yT39D4/Azac0uRQnH8KcYvvcUmnuHAoPQHJKU4zw
AAAED0TFRlch+3gmnC/IQr3uf+NaI8naRGs3q1d+j3omGZxy4b7JPf0Pj8DNpzS5FCcfwp
xi+9xSae4cCg9AckpTjPAAAAFnJoY3NhLXNpbXVsYXRvci1yZXBsYXkBAgMEBQYH
-----END OPENSSH PRIVATE KEY-----
EOF
printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4b7JPf0Pj8DNpzS5FCcfwpxi+9xSae4cCg9AckpTjP rhcsa-simulator-replay' > /home/elio/.ssh/id_ed25519.pub
chown elio:elio /home/elio/.ssh/id_ed25519 /home/elio/.ssh/id_ed25519.pub
chmod 0600 /home/elio/.ssh/id_ed25519
chmod 0644 /home/elio/.ssh/id_ed25519.pub
```

---

## Question 12 - Remote Account (server) - 5 pts

```bash
# Run on server
id backupf >/dev/null 2>&1 || useradd -m backupf
echo cinder9 | passwd --stdin backupf
mkdir -p /home/backupf/inbox
chown backupf:backupf /home/backupf/inbox
chmod 0755 /home/backupf/inbox
```

---

## Question 13 - Passwordless SSH (server) - 4 pts

```bash
# Run on server
install -d -m 700 -o backupf -g backupf /home/backupf/.ssh
printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4b7JPf0Pj8DNpzS5FCcfwpxi+9xSae4cCg9AckpTjP rhcsa-simulator-replay' > /home/backupf/.ssh/authorized_keys
chown backupf:backupf /home/backupf/.ssh/authorized_keys
chmod 0600 /home/backupf/.ssh/authorized_keys
# Run on client
su - elio
ssh -p 2222 -o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null backupf@server true
```

---

## Question 14 - Rsync Transfer (client + server) - 4 pts

```bash
# Run on client
su - elio
rsync -e "ssh -p 2222 -o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" /opt/exam-f/aurora-report.txt backupf@server:/home/backupf/inbox/report.txt
```

---

## Question 15 - User Umask (client) - 4 pts

```bash
echo 'umask 027' >> /home/elio/.bash_profile
```

---

## Question 16 - Find And Copy (client) - 4 pts

```bash
mkdir -p /root/seekerf-files
find /opt/exam-f/find -user seekerf -mtime -1 -type f -exec cp --parents {} /root/seekerf-files \;
```

---

## Question 17 - Grep Filter (client) - 4 pts

```bash
grep comet /usr/share/dict/words > /root/comet-lines
```

---

## Question 18 - Archive (client) - 4 pts

```bash
tar -czf /root/usr-local-f.tar.gz /usr/local
```

---

## Question 19 - Shell Script (client) - 4 pts

```bash
cat > /usr/local/bin/aurora-report <<'SCRIPT'
#!/bin/bash
> /root/aurora-units.txt
for unit in $(cat /usr/local/share/exam-f/units.lst); do
  systemctl is-active "$unit" >> /root/aurora-units.txt || true
done
SCRIPT
chmod +x /usr/local/bin/aurora-report
/usr/local/bin/aurora-report
```

---

## Question 20 - Swap Space (client) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 705MiB
blockdev --rereadpt /dev/sdb || true
partprobe /dev/sdb || true
partx -u /dev/sdb || partx -a /dev/sdb || true
udevadm settle
for attempt in 1 2 3 4 5 6 7 8 9 10; do test -b /dev/sdb1 && break; blockdev --rereadpt /dev/sdb || true; partprobe /dev/sdb || true; partx -u /dev/sdb || partx -a /dev/sdb || true; udevadm settle; sleep 1; done
test -b /dev/sdb1
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 21 - Create And Mount LV (client) - 4 pts

```bash
umount /mnt/reviewa /mnt/reviewb /mnt/reviewc /mnt/summitlv /mnt/auroralv /mnt/deltalv /mnt/reviewh >/dev/null 2>&1 || true
swapoff /dev/sdc1 >/dev/null 2>&1 || true
for vg in reviewvga reviewvgb reviewvgc summitvg auroravg deltavg reviewvgh; do vgchange -an "$vg" >/dev/null 2>&1 || true; vgremove -ff "$vg" >/dev/null 2>&1 || true; done
pvremove -ff -y /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc1 >/dev/null 2>&1 || true
wipefs -a /dev/sdc >/dev/null 2>&1 || true
sed -i -E '\# /mnt/(reviewa|reviewb|reviewc|summitlv|auroralv|deltalv|reviewh) #d' /etc/fstab
parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 100% set 1 lvm on
blockdev --rereadpt /dev/sdc || true
partprobe /dev/sdc || true
partx -u /dev/sdc || partx -a /dev/sdc || true
udevadm settle
for attempt in 1 2 3 4 5 6 7 8 9 10; do test -b /dev/sdc1 && break; blockdev --rereadpt /dev/sdc || true; partprobe /dev/sdc || true; partx -u /dev/sdc || partx -a /dev/sdc || true; udevadm settle; sleep 1; done
test -b /dev/sdc1
pvcreate /dev/sdc1
vgcreate -s 8M auroravg /dev/sdc1
lvcreate -y -W y -n auroralv -l 50 auroravg
mkfs.xfs -f /dev/auroravg/auroralv
mkdir -p /mnt/auroralv
uuid=$(blkid -s UUID -o value /dev/auroravg/auroralv)
echo "UUID=$uuid /mnt/auroralv xfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 22 - Recommended Tuned Profile (client) - 4 pts

```bash
rec="$(tuned-adm recommend | awk 'NF{print $1; exit}')"
test -n "$rec"
tuned-adm profile "$rec"
```
