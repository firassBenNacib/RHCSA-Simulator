#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh

mkdir -p /exports/direct /exports/autofs/field-guide
echo "Reference bundle for Mock Exam A" > /exports/direct/README.txt
echo "On-demand research notes" > /exports/autofs/field-guide/brief.txt
exportfs -arv
