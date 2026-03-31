#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

userdel -r analyst >/dev/null 2>&1 || true
groupdel sysmgrs >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/sysmgrs-httpd
rm -rf /home/analyst
rm -f /home/analyst/servervm-objectives.txt
mkdir -p /home/admin/.ssh
if [[ ! -f /home/admin/.ssh/id_rsa ]]; then
  ssh-keygen -q -t rsa -N '' -f /home/admin/.ssh/id_rsa
fi
chown -R admin:admin /home/admin/.ssh
chmod 700 /home/admin/.ssh
