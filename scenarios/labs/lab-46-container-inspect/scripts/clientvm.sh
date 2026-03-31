#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id inspect46 >/dev/null 2>&1 || useradd -m inspect46
printf 'inspect46:redhat
' | chpasswd
runuser -l inspect46 -c 'podman rmi -f localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || true'
rm -f /home/inspect46/workdir.txt /home/inspect46/user.txt
