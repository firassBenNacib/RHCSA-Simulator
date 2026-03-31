#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh
rhcsa_configure_password_recovery disable
rhcsa_configure_password_recovery enable
