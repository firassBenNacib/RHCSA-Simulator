#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh

rm -rf /root/rhcsa10-found
install -m 0644 /dev/null /etc/skel/rhcsa10-small.conf
touch -t 202001010101 /etc/skel/rhcsa10-small.conf
