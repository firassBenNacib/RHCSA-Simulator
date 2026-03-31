#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


mkdir -p /exports/netuser8
printf 'autofs lab 08
' > /exports/netuser8/welcome.txt
exportfs -arv
