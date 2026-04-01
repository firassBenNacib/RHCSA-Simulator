# Lab 14: User With Fixed UID

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-14-user-fixed-uid` |
| Mode | Lab |
| Time limit | 15 minutes |
| Objectives | users-sudo-ssh |

Create a local user with a specific UID.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 - Create user tavric with UID 4111 and set its password…
**System:** clientvm

Create user tavric with UID 4111 and set its password to cinder9.

### Hints
- Use passwd interactively.

### Validation Commands
```bash
id tavric
```
