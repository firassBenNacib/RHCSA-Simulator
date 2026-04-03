#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id orien19 >/dev/null 2>&1 || useradd -m orien19
rm -f /etc/profile.d/lab19-greeting.sh
python - <<'EOF'
from pathlib import Path
p = Path('/home/orien19/.bash_profile')
if p.exists():
    lines = [line for line in p.read_text().splitlines() if 'Welcome to you, user Orien, you are amazing!' not in line]
    p.write_text('\n'.join(lines) + ('\n' if lines else ''))
EOF
