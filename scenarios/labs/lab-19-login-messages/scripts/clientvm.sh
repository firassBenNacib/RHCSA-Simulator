#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


id orien19 >/dev/null 2>&1 || useradd -m orien19
python - <<'EOF'
from pathlib import Path
for p in [Path('/home/orien19/.bash_profile'), Path('/etc/profile.d/lab19-greeting.sh')]:
    try:
        p.unlink()
    except FileNotFoundError:
        pass
EOF
