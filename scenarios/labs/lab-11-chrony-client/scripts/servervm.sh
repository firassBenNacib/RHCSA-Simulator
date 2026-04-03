#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
systemctl disable --now chronyd >/dev/null 2>&1 || true
rm -f /etc/chrony.d/lab11-server.conf
python - <<'EOF'
from pathlib import Path
p = Path('/etc/chrony.conf')
lines = [line for line in p.read_text().splitlines() if not line.strip().startswith('allow ')]
p.write_text('\n'.join(lines) + '\n')
EOF
