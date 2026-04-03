# Lab 19: Login Greeting Messages

## Lab Solution
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

```bash
useradd -m orien19
printf 'echo "Welcome to you, user Orien, you are amazing!"
' >> /home/orien19/.bash_profile
chown orien19:orien19 /home/orien19/.bash_profile
```

---

## Task 02 - Create the global login greeting on both systems (clientvm) - 15 pts

```bash
cat > /etc/profile.d/lab19-greeting.sh <<'EOF'
echo "Welcome ${USER}, you are logged in!"
EOF
chmod 644 /etc/profile.d/lab19-greeting.sh
```

---

## Verification
```bash
test -f /etc/profile.d/lab19-greeting.sh && grep -Fq 'Welcome ${USER}, you are logged in!' /etc/profile.d/lab19-greeting.sh
ssh admin@servervm test -f /etc/profile.d/lab19-greeting.sh && ssh admin@servervm grep -Fq 'Welcome ${USER}, you are logged in!' /etc/profile.d/lab19-greeting.sh
ssh admin@servervm test -f /home/orien19/.bash_profile && ssh admin@servervm grep -Fq 'Welcome to you, user Orien, you are amazing!' /home/orien19/.bash_profile
```
