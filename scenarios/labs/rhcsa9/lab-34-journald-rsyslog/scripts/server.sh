#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
rm -rf /var/log/journal
rm -f /etc/rsyslog.d/10-auth34.conf /var/log/auth34.log
python - <<'EOF'
from pathlib import Path
p = Path('/etc/systemd/journald.conf')
text = p.read_text()
lines=[]
for line in text.splitlines():
    if line.strip().startswith('Storage='):
        continue
    lines.append(line)
p.write_text('\n'.join(lines)+'\n')
EOF
systemctl restart systemd-journald >/dev/null 2>&1 || true
systemctl restart rsyslog >/dev/null 2>&1 || true
