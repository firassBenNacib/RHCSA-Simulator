#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


id nico19 >/dev/null 2>&1 || useradd -m nico19
python - <<'EOF'
from pathlib import Path
for p in [Path('/home/nico19/.bash_profile'), Path('/etc/profile.d/lab19-greeting.sh')]:
    try:
        p.unlink()
    except FileNotFoundError:
        pass
EOF
