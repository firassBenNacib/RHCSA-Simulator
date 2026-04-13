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
- servervm
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the per-user greeting on servervm (servervm) - 15 pts

```bash
id orien19 >/dev/null 2>&1 || useradd -m orien19
echo 'echo "Welcome to you, user Orien, you are amazing!"' >> /home/orien19/.bash_profile
chown orien19:orien19 /home/orien19/.bash_profile
```

---

## Task 02 - Create the global login greeting on both systems (clientvm) - 15 pts

```bash
cat > /etc/profile.d/lab19-greeting.sh <<'EOF'
echo "Welcome ${USER}, you are logged in!"
EOF
chmod 644 /etc/profile.d/lab19-greeting.sh
# Run on servervm
cat > /etc/profile.d/lab19-greeting.sh <<'EOF'
echo "Welcome ${USER}, you are logged in!"
EOF
chmod 644 /etc/profile.d/lab19-greeting.sh
```
