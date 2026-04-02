# Lab 19: Login Greeting Messages

## Lab Solution
## Overview
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

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure a login message for user orien19 that (clientvm) - 10 pts

```bash
id orien19 || useradd -m orien19
vim /home/orien19/.bash_profile
echo "Welcome to you, user Orien, you are amazing!"
```

---

## Task 02 - Configure a global login message so any user (clientvm) - 10 pts

```bash
vim /etc/profile.d/lab19-greeting.sh
echo "Welcome ${USER}, you are logged in!"
```

---

## Verification
```bash
id orien19 >/dev/null && grep -Fqx 'echo "Welcome to you, user Orien, you are amazing!"' /home/orien19/.bash_profile
grep -Fqx 'echo "Welcome ${USER}, you are logged in!"' /etc/profile.d/lab19-greeting.sh
```
