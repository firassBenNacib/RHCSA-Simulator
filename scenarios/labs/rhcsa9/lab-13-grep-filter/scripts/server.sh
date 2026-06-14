#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


mkdir -p /usr/share/dict
cat > /usr/share/dict/words <<'EOF'
which
rich
hello
stitch
alpha
EOF
rm -f /root/lines
