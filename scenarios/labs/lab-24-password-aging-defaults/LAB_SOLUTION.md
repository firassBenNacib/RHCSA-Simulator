# Lab 24: Password Aging Defaults

## Lab Solution
## Overview
| Field | Value |
|---|---|
| Scenario ID | `lab-24-password-aging-defaults` |
| Mode | Lab |
| Time limit | 30 minutes |
| Objectives | users-sudo-ssh |

Configure stronger new-user aging defaults, including inactive days.

### Systems
- clientvm

## General Instructions
1. Unless a task states otherwise, make all changes persistent across reboots.
2. Use only persistent configuration methods.
3. Use vim, visudo, crontab -e, and the normal RHCSA command flow when editing files.

## Task 01 - Set password aging defaults in login.defs (clientvm) - 10 pts

```bash
python - <<'EOF'
from pathlib import Path
p = Path('/etc/login.defs')
text = p.read_text()
for key, value in [('PASS_MAX_DAYS', '60'), ('PASS_MIN_DAYS', '7'), ('PASS_WARN_AGE', '10')]:
    lines = []
    replaced = False
    for line in text.splitlines():
        if line.startswith(key):
            lines.append(f'{key}	{value}')
            replaced = True
        else:
            lines.append(line)
    if not replaced:
        lines.append(f'{key}	{value}')
    text = '\n'.join(lines) + '\n'
p.write_text(text)
EOF
```

---

## Task 02 - Set the useradd inactive default (clientvm) - 10 pts

```bash
useradd -D -f 15
```

---

## Task 03 - Create drift24 with the inherited defaults (clientvm) - 10 pts

```bash
useradd drift24
printf 'drift24:cinder9\n' | chpasswd
```
