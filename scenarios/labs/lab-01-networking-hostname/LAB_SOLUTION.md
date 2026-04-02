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
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection show "$CONN"
nmcli connection modify "$CONN" ipv4.addresses 192.168.122.25/24 ipv4.gateway 192.168.122.1 ipv4.dns 192.168.122.3 ipv4.method manual connection.autoconnect yes
nmcli connection down "$CONN"
nmcli connection up "$CONN"
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
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"
nmcli connection show "$CONN"
nmcli connection show "$CONN"
hostnamectl status
getent hosts repo.netlab.local
```

---

## Verification
```bash
hostnamectl --static | grep -qx 'clientvm.netlab.local'
CONN="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2 != "" && $2 != "lo" {print $1; exit}')"; test -n "$CONN"; test "$(nmcli -g ipv4.addresses connection show "$CONN")" = '192.168.122.25/24' && test "$(nmcli -g ipv4.gateway connection show "$CONN")" = '192.168.122.1' && test "$(nmcli -g ipv4.dns connection show "$CONN")" = '192.168.122.3' && test "$(nmcli -g ipv4.method connection show "$CONN")" = 'manual'
grep -Eq '^192\.168\.122\.3[[:space:]]+repo\.netlab\.local([[:space:]]|$)' /etc/hosts
```
