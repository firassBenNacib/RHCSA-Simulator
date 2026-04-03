# Lab 01: Networking And Hostname

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-01-networking-hostname` |
| Mode | Lab |
| Time limit | 35 minutes |
| Objectives | networking-and-firewall |

Configure persistent networking and hostname settings on clientvm in RHCSA style.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Client Network Configuration (clientvm) - 10 pts

```bash
nmcli device status
nmcli connection show "System eth1"
nmcli connection modify "System eth1" ipv4.addresses 192.168.122.25/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "System eth1"
nmcli connection up "System eth1"
hostnamectl set-hostname clientvm.netlab.local
```

---

## Task 02 - Static Host Entry (clientvm) - 10 pts

```bash
vim /etc/hosts
192.168.122.3 repo.netlab.local
```

---

## Task 03 - Reconnect Verification (clientvm) - 10 pts

```bash
nmcli device status
nmcli connection show "System eth1"
hostnamectl status
getent hosts repo.netlab.local
```
