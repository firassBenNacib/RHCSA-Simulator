# Lab 29: Firewalld Rich Rule

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-29-firewalld-rich-rule` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | networking-and-firewall |

Use a persistent rich rule to restrict access to a custom port by source network.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure a persistent firewalld rich rule that (clientvm) - 10 pts

Configure a persistent firewalld rich rule that allows TCP port 2222 only from the source network 192.168.122.0/24.

---

## Task 02 - Reload firewalld and verify that the rule is active (clientvm) - 10 pts

Reload firewalld and verify that the rule is active.
