# Lab 25: Pwquality Policy

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-25-pwquality-policy` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | users-sudo-ssh |

Configure a persistent local password quality policy without editing PAM service files.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Create a persistent password quality policy in…
**System:** clientvm

Create a persistent password quality policy in /etc/security/pwquality.conf.d so that local passwords must meet the following requirements:

- **Minimum Length:** 12
- **Minimum Character Classes:** 3

---

### Task 02 - Do not edit any PAM service file for this task
**System:** clientvm

Do not edit any PAM service file for this task.

### Hints
- Use a dedicated drop-in file.
- Keep the configuration minimal.

### Validation Commands
```bash
grep -R "minlen\|minclass" /etc/security/pwquality.conf.d
```
