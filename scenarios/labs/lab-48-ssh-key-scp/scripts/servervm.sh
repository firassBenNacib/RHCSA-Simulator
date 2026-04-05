#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id bridge48 >/dev/null 2>&1 || useradd -m bridge48
passwd -l bridge48 >/dev/null 2>&1 || true
rm -rf /home/bridge48/.ssh /home/bridge48/inbox
mkdir -p /home/bridge48/inbox
chown -R bridge48:bridge48 /home/bridge48
python - <<'EOF'
from pathlib import Path
import re
p = Path('/etc/ssh/sshd_config')
text = p.read_text()
for key, val in [('PasswordAuthentication', 'yes'), ('PubkeyAuthentication', 'yes')]:
    if re.search(rf'^\s*{key}\s+', text, flags=re.M):
        text = re.sub(rf'^\s*{key}\s+.*$', f'{key} {val}', text, flags=re.M)
    else:
        text += f'\n{key} {val}\n'
p.write_text(text)
EOF
systemctl restart sshd >/dev/null 2>&1 || true
