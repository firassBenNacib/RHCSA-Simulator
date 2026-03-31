#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id key39 >/dev/null 2>&1 || useradd -m key39
printf 'key39:redhat\n' | chpasswd
rm -rf /home/key39/.ssh /home/key39/server-data
mkdir -p /home/key39/server-data
chown -R key39:key39 /home/key39
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
