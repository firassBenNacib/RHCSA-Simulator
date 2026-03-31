#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /exports/direct /exports/autofs/projects
echo "direct share ready" > /exports/direct/nfs_file.txt
echo "autofs map target" > /exports/autofs/projects/readme
exportfs -arv
