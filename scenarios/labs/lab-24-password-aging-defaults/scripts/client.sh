#!/usr/bin/env bash
set -euo pipefail
userdel -r drift24 >/dev/null 2>&1 || true
python - <<'EOF'
from pathlib import Path
p = Path('/etc/login.defs')
text = p.read_text()
for key, value in [('PASS_MAX_DAYS', '99999'), ('PASS_MIN_DAYS', '0'), ('PASS_WARN_AGE', '7')]:
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
python - <<'EOF'
from pathlib import Path
p = Path('/etc/default/useradd')
text = p.read_text() if p.exists() else ''
lines = []
replaced = False
for line in text.splitlines():
    if line.startswith('INACTIVE='):
        lines.append('INACTIVE=-1')
        replaced = True
    else:
        lines.append(line)
if not replaced:
    lines.append('INACTIVE=-1')
p.write_text('\n'.join(lines) + '\n')
EOF
