#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/rhcsa-scenario-helpers.sh
groupadd -f analystsx
rm -rf /shared/analysts
mkdir -p /shared
