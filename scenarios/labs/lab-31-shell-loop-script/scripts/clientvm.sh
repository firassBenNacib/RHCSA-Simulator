#!/usr/bin/env bash
            set -euo pipefail
            rm -f /usr/local/bin/listlogs31 /root/listlogs31.out
            mkdir -p /opt/lab31
            rm -f /opt/lab31/*
            printf 'a
' > /opt/lab31/app.log
            printf 'b
' > /opt/lab31/messages.log
            printf 'c
' > /opt/lab31/readme.txt
