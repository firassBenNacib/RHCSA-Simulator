# Mock Exam B

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22-task RHCSA practice mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.

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
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.27/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname client.exam-b.lab
```

---

## Question 02 - Host Entry (client) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 registry.exam-b.lab
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

## Question 05 - Useradd Defaults (client) - 5 pts

```bash
useradd -D -f 20
```

---

## Question 06 - No-Home UID User (client) - 5 pts

```bash
useradd -M -u 4421 cato421
echo cinder9 | passwd --stdin cato421
```

---

## Question 07 - Login User with Password Aging (client) - 5 pts

```bash
useradd jonas
echo cinder9 | passwd --stdin jonas
chage -M 45 -m 5 -W 7 jonas
```

---

## Question 08 - Pwquality Policy (client) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
cat > /etc/security/pwquality.conf.d/coremesh.conf <<'EOF'
minlen = 12
minclass = 3
EOF
```

---

## Question 09 - Delegated Sudo (client) - 5 pts

```bash
visudo -f /etc/sudoers.d/mira-firewalld
mira ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld
```

---

## Question 10 - SSH Port (server) - 5 pts

```bash
# Run on server
vim /etc/ssh/sshd_config
Port 22
Port 2222
PasswordAuthentication yes
PubkeyAuthentication yes
semanage port -l | grep -Eq '^ssh_port_t\b.*\b2222\b' || semanage port -a -t ssh_port_t -p tcp 2222
systemctl restart sshd
```

---

## Question 11 - Rich Rule (server) - 5 pts

```bash
# Run on server
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 12 - SSH Key Generation (client) - 5 pts

```bash
id mira >/dev/null 2>&1 || useradd mira
echo cinder9 | passwd --stdin mira
mkdir -p /home/mira/.ssh
chown mira:mira /home/mira/.ssh
chmod 0700 /home/mira/.ssh
test -f /home/mira/.ssh/id_ed25519 || runuser -u mira -- ssh-keygen -t ed25519 -N '' -f /home/mira/.ssh/id_ed25519 -C mira-exam-replay >/dev/null 2>&1
chmod 0600 /home/mira/.ssh/id_ed25519
chmod 0644 /home/mira/.ssh/id_ed25519.pub
```

---

## Question 13 - Passwordless SSH (client + server) - 4 pts

```bash
# Run on server
id meshremote >/dev/null 2>&1 || useradd meshremote
echo cinder9 | passwd --stdin meshremote
mkdir -p /home/meshremote/inbox
chown meshremote:meshremote /home/meshremote/inbox
chmod 0755 /home/meshremote/inbox
# Run on client
su - mira
ssh-copy-id -i /home/mira/.ssh/id_ed25519.pub -p 2222 meshremote@server
ssh -p 2222 -o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null meshremote@server true
```

---

## Question 14 - Rsync Transfer (client + server) - 4 pts

```bash
# Run on client
su - mira
rsync -e "ssh -p 2222 -o BatchMode=yes -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" /opt/exam-b/report.txt meshremote@server:/home/meshremote/inbox/report.txt
```

---

## Question 15 - User Umask (client) - 4 pts

```bash
echo 'umask 027' >> /home/mira/.bash_profile
```

---

## Question 16 - Find and Copy (client) - 4 pts

```bash
mkdir -p /root/mira-files
find /opt/exam-b/find -user mira -mtime -1 -type f -exec cp --parents {} /root/mira-files \;
```

---

## Question 17 - Grep Filter (client) - 4 pts

```bash
grep proto /usr/share/dict/words > /root/proto-lines
```

---

## Question 18 - Archive (client) - 4 pts

```bash
tar -cjf /root/usr-local-b.tar.bz2 /usr/local
```

---

## Question 19 - Shell Script (client) - 4 pts

```bash
cat > /usr/local/bin/corecheck <<'SCRIPT'
#!/bin/bash
> /root/coremesh-units.txt
for unit in $(cat /usr/local/share/exam-b/units.lst); do
  systemctl is-active "$unit" >> /root/coremesh-units.txt
done
SCRIPT
chmod +x /usr/local/bin/corecheck
/usr/local/bin/corecheck
```

---

## Question 20 - Swap Space (client) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 601MiB
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 21 - Create and Mount LV (client) - 4 pts

```bash
parted -s /dev/sdc -- mklabel gpt mkpart primary 1MiB 100% set 1 lvm on
partprobe /dev/sdc
pvcreate /dev/sdc1
vgcreate -s 8M reviewvgb /dev/sdc1
lvcreate -n reviewb -l 50 reviewvgb
mkfs.ext4 /dev/reviewvgb/reviewb
mkdir -p /mnt/reviewb
uuid=$(blkid -s UUID -o value /dev/reviewvgb/reviewb)
echo "UUID=$uuid /mnt/reviewb ext4 defaults 0 0" >> /etc/fstab
mount -a
```

---

## Question 22 - Recommended Tuned Profile (client) - 4 pts

```bash
tuned-adm profile "$(tuned-adm recommend)"
```
