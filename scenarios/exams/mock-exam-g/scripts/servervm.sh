#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-exam-g
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-g
mkdir -p /exports/delta-home
echo 'delta home' > /exports/delta-home/brief.txt
chown -R nobody:nobody /exports/delta-home
cat > /etc/exports.d/exam-g.exports <<'EOF'
/exports/delta-home 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
userdel -r copyg >/dev/null 2>&1 || true
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
