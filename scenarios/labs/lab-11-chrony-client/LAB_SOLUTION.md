# Lab 11: Time Synchronization

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-11-chrony-client` |
| Mode | Lab |
| Time limit | 20 minutes |
| Objectives | software-scheduling-time |

Configure servervm as a simple chrony source and point clientvm at it.

### Systems
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |
| servervm | Utility host for repos, NFS exports, time service, and cross-system tasks |

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Configure servervm as the chrony source (servervm) - 15 pts

```bash
printf 'allow 192.168.122.0/24
' > /etc/chrony.d/lab11-server.conf
systemctl enable --now chronyd
```

---

## Task 02 - Configure clientvm to use only servervm for time (clientvm) - 15 pts

```bash
printf 'server servervm iburst
' > /etc/chrony.d/lab11-client.conf
python - <<'EOF'
from pathlib import Path
p = Path('/etc/chrony.conf')
lines = [line for line in p.read_text().splitlines() if not line.strip().startswith(('server ', 'pool '))]
p.write_text('\n'.join(lines) + '\n')
EOF
systemctl enable --now chronyd
```
