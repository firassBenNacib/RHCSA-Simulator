#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/exports.d/lab36.exports
exportfs -ar >/dev/null 2>&1 || true
rm -rf /exports/direct36
systemctl restart nfs-server >/dev/null 2>&1 || true
