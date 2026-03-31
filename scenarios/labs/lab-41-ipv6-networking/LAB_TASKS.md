# Lab 41: IPv6 Networking

## Lab Tasks
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

### Task 01 — Configure the active clientvm connection with the…
**System:** clientvm

Configure the active clientvm connection with the following persistent IPv6 settings:

IPV6 ADDRESS: fd00:122:41::25/64
IPV6 GATEWAY: fd00:122:41::1
DNS SERVER: fd00:122:41::53

---

### Task 02 — Set the persistent hostname to clientvm.ipv6lab.local…
**System:** clientvm

Set the persistent hostname to clientvm.ipv6lab.local and add a persistent hosts entry so servervm.ipv6lab.local resolves to fd00:122:41::3.

---

### Task 03 — Leave the existing IPv4 configuration unchanged
**System:** clientvm

Leave the existing IPv4 configuration unchanged.

### Hints
- Use nmcli so the change survives a reconnect.

### Validation Commands
```bash
nmcli -t -f NAME,DEVICE connection show --active
hostnamectl --static
getent hosts servervm.ipv6lab.local
```
