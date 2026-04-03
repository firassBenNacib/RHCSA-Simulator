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
| System | Use |
|---|---|
| clientvm | Primary RHCSA workstation |

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
printf 'drift24:cinder9
' | chpasswd
```

---

## Verification
```bash
grep -Eq '^PASS_MAX_DAYS[[:space:]]+60$' /etc/login.defs && grep -Eq '^PASS_MIN_DAYS[[:space:]]+7$' /etc/login.defs && grep -Eq '^PASS_WARN_AGE[[:space:]]+10$' /etc/login.defs
useradd -D | grep -Eq '^INACTIVE=15$'
getent passwd drift24 >/dev/null && chage -l drift24 | grep -Fq 'Maximum number of days between password change			: 60' && chage -l drift24 | grep -Fq 'Minimum number of days between password change			: 7' && chage -l drift24 | grep -Fq 'Number of days of warning before password expires		: 10'
```
