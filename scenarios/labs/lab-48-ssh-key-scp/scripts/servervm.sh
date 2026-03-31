#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id copy48 >/dev/null 2>&1 || useradd -m copy48
printf 'copy48:redhat
' | chpasswd
rm -rf /home/copy48/.ssh /home/copy48/inbox
mkdir -p /home/copy48/inbox
chown -R copy48:copy48 /home/copy48
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
