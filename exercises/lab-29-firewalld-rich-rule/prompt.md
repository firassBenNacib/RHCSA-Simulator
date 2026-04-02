# Lab 29: Firewalld Rich Rule

Time: 20 minutes
Objectives: networking-and-firewall
Systems: clientvm

Use a persistent rich rule to restrict access to a custom port by source network.

## Tasks

## Task 01 - Configure a persistent firewalld rich rule that (clientvm) - 10 pts

Configure a persistent firewalld rich rule that allows TCP port 2222 only from the source network 192.168.122.0/24.

## Task 02 - Reload firewalld and verify that the rule is active (clientvm) - 10 pts

Reload firewalld and verify that the rule is active.

## Validation

Use the generated `check.sh` file or the host command below after you finish:

`./RHCSA.ps1 check`
