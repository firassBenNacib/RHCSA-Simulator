#!/usr/bin/env bash
set -euo pipefail

source /usr/local/lib/rhcsa-scenario-helpers.sh


id natfind >/dev/null 2>&1 || useradd -m natfind
rm -rf /opt/lab12 /root/natfind-files
mkdir -p /opt/lab12/source/a /opt/lab12/source/b/sub
printf 'one
' > /opt/lab12/source/a/report1.txt
printf 'two
' > /opt/lab12/source/b/sub/report2.txt
printf 'old
' > /opt/lab12/source/b/sub/ignore.txt
chown -R natfind:natfind /opt/lab12/source
touch -d '2 days ago' /opt/lab12/source/b/sub/ignore.txt
