#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-scripts
rhcsa_reset_repo_directory /root/.repo-backup-server-scripts
userdel -r meshremote >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="192.168.122.0/24" port protocol="tcp" port="2222" accept' >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null 2>&1 || true
python - <<'EOF'
from pathlib import Path
import re
p = Path('/etc/ssh/sshd_config')
text = p.read_text()
for key, val in [('Port', '22'), ('PasswordAuthentication', 'yes'), ('PubkeyAuthentication', 'yes')]:
    if re.search(rf'^\s*{key}\s+', text, flags=re.M):
        text = re.sub(rf'^\s*{key}\s+.*$', f'{key} {val}', text, flags=re.M)
    else:
        text += f'\n{key} {val}\n'
p.write_text(text)
EOF
systemctl restart sshd >/dev/null 2>&1 || true
systemctl disable --now chronyd >/dev/null 2>&1 || true
python - <<'EOF'
from pathlib import Path
p = Path('/etc/chrony.conf')
lines = []
for line in p.read_text().splitlines():
    stripped = line.strip()
    if stripped.startswith('server ') or stripped.startswith('pool ') or stripped.startswith('allow ') or stripped.startswith('local stratum'):
        continue
    lines.append(line)
p.write_text('\n'.join(lines) + '\n')
EOF
mkdir -p /exports/meshb
echo 'exam b mesh' > /exports/meshb/notes.txt
chown -R nobody:nobody /exports/meshb
cat > /etc/exports.d/exam-b.exports <<'EOF'
/exports/meshb 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
