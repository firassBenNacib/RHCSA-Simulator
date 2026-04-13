# Mock Exam B

## Exam Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `mock-exam-b` |
| Mode | Exam |
| Time limit | 150 minutes |
| Objectives | networking-and-firewall, users-sudo-ssh, processes-logs-tuning, storage-lvm |

A 22 task RHCSA style mock exam emphasizing chrony, SSH hardening, user defaults, and storage administration.

### Systems
- clientvm
- servervm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Read the whole handout before you begin so you can sequence cross-system work efficiently.
3. Use the exact scenario variables shown in each question.
4. Keep SELinux enforcing unless a question explicitly directs otherwise.

## Question 01 - Client Network (clientvm) - 5 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.27/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.exam-b.lab
```

---

## Question 02 - Host Entry (clientvm) - 5 pts

```bash
vim /etc/hosts
192.168.122.3 registry.exam-b.lab
```

---

## Question 03 - Chrony Server (servervm) - 5 pts

```bash
# Run on servervm
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

## Question 04 - Chrony Client (clientvm) - 5 pts

```bash
cat > /etc/chrony.conf <<'EOF'
server servervm iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF
systemctl enable --now chronyd
```

---

## Question 05 - Useradd Defaults (clientvm) - 5 pts

```bash
useradd -D -f 20
```

---

## Question 06 - No-Home UID User (clientvm) - 5 pts

```bash
useradd -M -u 4421 cato421
echo cinder9 | passwd --stdin cato421
```

---

## Question 07 - Primary Login User (clientvm) - 5 pts

```bash
id mira >/dev/null 2>&1 || useradd -m mira
echo cinder9 | passwd --stdin mira
```

---

## Question 08 - Password Aging (clientvm) - 5 pts

```bash
useradd jonas
echo cinder9 | passwd --stdin jonas
chage -M 45 -m 5 -W 7 jonas
```

---

## Question 09 - Pwquality Policy (clientvm) - 5 pts

```bash
mkdir -p /etc/security/pwquality.conf.d
cat > /etc/security/pwquality.conf.d/coremesh.conf <<'EOF'
minlen = 12
minclass = 3
EOF
```

---

## Question 10 - Delegated Sudo (clientvm) - 5 pts

```bash
visudo -f /etc/sudoers.d/mira-firewalld
mira ALL=(root) NOPASSWD: /usr/bin/systemctl restart firewalld
```

---

## Question 11 - SSH Port (servervm) - 5 pts

```bash
# Run on servervm
vim /etc/ssh/sshd_config
Port 22
Port 2222
PasswordAuthentication yes
PubkeyAuthentication yes
semanage port -a -t ssh_port_t -p tcp 2222 2>/dev/null || semanage port -m -t ssh_port_t -p tcp 2222
systemctl restart sshd
```

---

## Question 12 - Rich Rule (servervm) - 5 pts

```bash
# Run on servervm
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept'
firewall-cmd --reload
```

---

## Question 13 - SSH Key Generation (clientvm) - 4 pts

```bash
# Run on clientvm
su - mira
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

---

## Question 14 - Passwordless SSH (servervm) - 4 pts

```bash
# Run on servervm
id meshremote >/dev/null 2>&1 || useradd -m meshremote
echo cinder9 | passwd --stdin meshremote
mkdir -p /home/meshremote/inbox
chown meshremote:meshremote /home/meshremote/inbox
chmod 0755 /home/meshremote/inbox
# Run on clientvm
su - mira
ssh-copy-id -p 2222 meshremote@servervm
ssh -p 2222 -o BatchMode=yes meshremote@servervm true
```

---

## Question 15 - Rsync Transfer (servervm) - 4 pts

```bash
# Run on clientvm
su - mira
rsync -e "ssh -p 2222" /opt/exam-b/report.txt meshremote@servervm:/home/meshremote/inbox/report.txt
```

---

## Question 16 - Find Copy Preserve (clientvm) - 4 pts

```bash
mkdir -p /root/mira-files
find /opt/exam-b/find -user mira -mtime -1 -type f -exec cp --parents {} /root/mira-files \;
```

---

## Question 17 - Grep Filter (clientvm) - 4 pts

```bash
grep proto /usr/share/dict/words > /root/proto-lines
```

---

## Question 18 - Archive /usr/local (clientvm) - 4 pts

```bash
tar -cjf /root/usr-local-b.tar.bz2 /usr/local
```

---

## Question 19 - Service Report Script (clientvm) - 4 pts

```bash
vim /usr/local/bin/corecheck
#!/usr/bin/env bash
> /root/coremesh-units.txt
while read -r unit; do
  systemctl is-active "$unit" >> /root/coremesh-units.txt
done < /usr/local/share/exam-b/units.lst
chmod 755 /usr/local/bin/corecheck
/usr/local/bin/corecheck
```

---

## Question 20 - Swap Space (clientvm) - 4 pts

```bash
parted -s /dev/sdb -- mklabel gpt mkpart primary linux-swap 1MiB 641MiB
partprobe /dev/sdb
mkswap /dev/sdb1
swapon /dev/sdb1
uuid=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$uuid swap swap defaults 0 0" >> /etc/fstab
```

---

## Question 21 - Resize LV (clientvm) - 4 pts

```bash
lvextend -L 300M /dev/reviewvgb/reviewb
resize2fs /dev/reviewvgb/reviewb
```

---

## Question 22 - Apply Tuned (clientvm) - 4 pts

```bash
tuned-adm profile "$(tuned-adm recommend)"
```
