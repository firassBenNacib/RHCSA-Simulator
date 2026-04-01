# Lab 29: Firewalld Rich Rule

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-29-firewalld-rich-rule` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | networking-and-firewall |

Use a persistent rich rule to restrict access to a custom port by source network.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Configure a persistent firewalld rich rule that…
**System:** clientvm

Configure a persistent firewalld rich rule that allows TCP port 2222 only from the source network 192.168.122.0/24.

---

### Task 02 - Reload firewalld and verify that the rule is active
**System:** clientvm

Reload firewalld and verify that the rule is active.

### Hints
- Use firewall-cmd --permanent --add-rich-rule.
- List the effective rich rules after reloading.

### Validation Commands
```bash
firewall-cmd --list-rich-rules
```
