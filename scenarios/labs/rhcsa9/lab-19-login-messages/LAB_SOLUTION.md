# Lab 19: Login Greeting Messages

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-19-login-messages` |
| Mode | Lab |
| Scope | client-server |
| Time limit | 25 minutes |
| Objectives | users-sudo-ssh |

Configure both a user-specific and a global login greeting with clearer host distribution.

### Systems
- server
- client

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Create the per-user greeting on server (server) - 10 pts

```bash
# On server
id orien19 >/dev/null 2>&1 || useradd -m orien19
echo 'echo "Welcome to you, user Orien, you are amazing!"' >> /home/orien19/.bash_profile
chown orien19:orien19 /home/orien19/.bash_profile
```

---

## Task 02 - Create the global login greeting on client (client) - 10 pts

```bash
# On client
cat > /etc/profile.d/lab19-greeting.sh <<'EOF'
echo "Welcome ${USER}, you are logged in!"
EOF
chmod 644 /etc/profile.d/lab19-greeting.sh
```

---

## Task 03 - Create the global login greeting on server (server) - 10 pts

```bash
# On server
cat > /etc/profile.d/lab19-greeting.sh <<'EOF'
echo "Welcome ${USER}, you are logged in!"
EOF
chmod 644 /etc/profile.d/lab19-greeting.sh
```
