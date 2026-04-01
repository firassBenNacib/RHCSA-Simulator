#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
id scope46 >/dev/null 2>&1 || useradd -m scope46
printf 'scope46:cinder9
' | chpasswd
runuser -l scope46 -c 'podman rmi -f localhost/rhcsa-httpd-base:latest >/dev/null 2>&1 || true'
rm -f /home/scope46/workdir.txt /home/scope46/user.txt
