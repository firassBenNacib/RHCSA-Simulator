#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
mkdir -p /root/.repo-backup-server-exam-h
rhcsa_reset_repo_directory /root/.repo-backup-server-exam-h
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
mkdir -p /exports/silverhome
printf 'silver export
' > /exports/silverhome/brief.txt
chown -R nobody:nobody /exports/silverhome
cat > /etc/exports.d/exam-h.exports <<'EOF'
/exports/silverhome 192.168.122.0/24(rw,sync,no_root_squash)
EOF
systemctl enable --now nfs-server >/dev/null 2>&1 || true
exportfs -arv >/dev/null 2>&1 || true
