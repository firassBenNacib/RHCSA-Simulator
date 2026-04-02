# Lab 01: Networking And Hostname

Time: 35 minutes
Objectives: networking-and-firewall
Systems: clientvm

Configure persistent networking and hostname settings on clientvm in RHCSA style.

## Tasks

## Task 01 - Client Network Configuration (clientvm) - 10 pts

Configure the active clientvm connection with the following persistent settings:

- **IP Address:** 192.168.122.25
- **Netmask:** 255.255.255.0
- **Gateway:** 192.168.122.1
- **DNS Server:** 192.168.122.3
- **Hostname:** clientvm.netlab.local

## Task 02 - Static Host Entry (clientvm) - 10 pts

Add a persistent hosts entry with the following value:

- **Hostname:** repo.netlab.local
- **Address:** 192.168.122.3

## Task 03 - Reconnect Verification (clientvm) - 10 pts

Verify that the active connection comes back with the same values after reconnecting it.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
