# Lab 01: Networking And Hostname

## Lab Solution
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-01-networking-hostname` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | networking-and-firewall |

Configure persistent networking and hostname settings on clientvm in RHCSA style.

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.

## Task 01 — Part 01
**System:** clientvm

#### Commands
```bash
nmcli connection show
nmcli connection modify "<active-connection>" ipv4.addresses 192.168.122.25/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "<active-connection>"
nmcli connection up "<active-connection>"
hostnamectl set-hostname clientvm.netlab.local
```

---

## Task 02 — Part 02
**System:** clientvm

#### Commands
```bash
vim /etc/hosts
192.168.122.3 repo.netlab.local
```

---

## Task 03 — Part 03
**System:** clientvm

#### Commands
```bash
nmcli connection show "<active-connection>"
hostnamectl status
getent hosts repo.netlab.local
```

---

### Verification
```bash
hostnamectl status
nmcli connection show --active
getent hosts repo.netlab.local
```
