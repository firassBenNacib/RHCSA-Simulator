# Lab 19: Login Greeting Messages

## Lab Tasks
### Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-19-login-messages` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Configure user specific and global shell greetings.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

### General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

### Task 01 — Configure a login message for user nico19 that says:…
**System:** clientvm

Configure a login message for user nico19 that says: Welcome to you, user Nico, you are amazing!

---

### Task 02 — Configure a global login message so any user…
**System:** clientvm

Configure a global login message so any user receives: Welcome [username], you are logged in! with the actual login name.

### Hints
- A profile script under /etc/profile.d is acceptable for the global message.
- A user profile file is acceptable for the user specific message.

### Validation Commands
```bash
su - nico19 -c true
su - admin -c true
```
