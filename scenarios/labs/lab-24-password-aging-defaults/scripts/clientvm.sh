#!/usr/bin/env bash
            set -euo pipefail
            userdel -r aging24 >/dev/null 2>&1 || true
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
    text = '
'.join(lines) + '
'
p.write_text(text)
EOF
