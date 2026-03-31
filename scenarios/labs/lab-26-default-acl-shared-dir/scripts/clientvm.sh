#!/usr/bin/env bash
set -euo pipefail
userdel -r qa26 >/dev/null 2>&1 || true
groupdel collab26 >/dev/null 2>&1 || true
rm -rf /shared/collab26
