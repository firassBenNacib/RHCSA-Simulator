# Lab 19: Login Greeting Messages

## Lab Tasks
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-19-login-messages` |
| Mode | Lab |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Configure both a user-specific and a global login greeting with clearer host distribution.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the per-user greeting on servervm (servervm) - 15 pts

On servervm, configure a login message for user orien19 that says: Welcome to you, user Orien, you are amazing!

---

## Task 02 - Create the global login greeting on both systems (clientvm) - 15 pts

Configure a global login message on both clientvm and servervm so any user receives: Welcome [username], you are logged in! with the actual login name.

## Hints
- Per-user shell startup content belongs in the user home.
- A profile.d script is the cleanest way to apply the same greeting globally.

## Validation Commands
```bash
test -f /etc/profile.d/lab19-greeting.sh && grep -Fq 'Welcome ${USER}, you are logged in!' /etc/profile.d/lab19-greeting.sh
ssh admin@servervm test -f /etc/profile.d/lab19-greeting.sh && ssh admin@servervm grep -Fq 'Welcome ${USER}, you are logged in!' /etc/profile.d/lab19-greeting.sh
ssh admin@servervm test -f /home/orien19/.bash_profile && ssh admin@servervm grep -Fq 'Welcome to you, user Orien, you are amazing!' /home/orien19/.bash_profile
```
