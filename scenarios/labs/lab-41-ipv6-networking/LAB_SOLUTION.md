# Lab 41: IPv6 Networking

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-41-ipv6-networking` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | networking-and-firewall |

Configure persistent IPv6 networking and hostname resolution on the client system.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Configure the active clientvm connection with the…
**System:** clientvm

#### Command Flow
```bash
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection modify "$CONN" ipv6.method manual ipv6.addresses fd00:122:41::25/64 ipv6.gateway fd00:122:41::1 ipv6.dns fd00:122:41::53 connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
```

---

### Task 02 - Set the persistent hostname to clientvm.ipv6lab.local…
**System:** clientvm

#### Command Flow
```bash
hostnamectl set-hostname clientvm.ipv6lab.local
vim /etc/hosts
fd00:122:41::3 servervm.ipv6lab.local
:wq
```

---

### Task 03 - Leave the existing IPv4 configuration unchanged
**System:** clientvm

#### Command Flow
```bash
nmcli connection show "$CONN" | grep -E "ipv6.addresses|ipv6.gateway|ipv6.dns"
getent hosts servervm.ipv6lab.local
```

---

### Verification
```bash
nmcli -t -f NAME,DEVICE connection show --active
hostnamectl --static
getent hosts servervm.ipv6lab.local
```
