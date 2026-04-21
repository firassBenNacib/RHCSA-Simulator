#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id mesh39 >/dev/null 2>&1 || useradd -m mesh39
passwd -l mesh39 >/dev/null 2>&1 || true
rm -rf /home/mesh39/.ssh /home/mesh39/server-data
mkdir -p /home/mesh39/server-data
chown -R mesh39:mesh39 /home/mesh39
python - <<'EOF'
from pathlib import Path
p = Path('/etc/ssh/sshd_config')
text = p.read_text()
for key,val in [('PasswordAuthentication','yes'),('PubkeyAuthentication','yes')]:
    import re
    if re.search(rf'^\s*{key}\s+', text, flags=re.M):
        text = re.sub(rf'^\s*{key}\s+.*$', f'{key} {val}', text, flags=re.M)
    else:
        text += f'\n{key} {val}\n'
p.write_text(text)
EOF
systemctl restart sshd >/dev/null 2>&1 || true
