# Lab 01: Networking And Hostname

## Lab Tasks
### Overview
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

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Configure the active clientvm connection with the…
**System:** clientvm

Configure the active clientvm connection with the IPv4 address 192.168.122.25/24, gateway 192.168.122.1, DNS server 192.168.122.3, and set the persistent hostname to clientvm.netlab.local.

---

### Task 02 - Add a persistent host entry so repo.netlab.local…
**System:** clientvm

Add a persistent host entry so repo.netlab.local resolves to 192.168.122.3.

---

### Task 03 - Verify that the active connection comes back with the…
**System:** clientvm

Verify that the active connection comes back with the same values after reconnecting it.

### Hints
- Use nmcli or nmtui for the network profile.
- Use hostnamectl for the persistent hostname.

### Validation Commands
```bash
hostnamectl status
nmcli connection show --active
getent hosts repo.netlab.local
```
