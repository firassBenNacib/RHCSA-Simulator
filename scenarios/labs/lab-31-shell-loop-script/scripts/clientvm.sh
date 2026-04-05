#!/usr/bin/env bash
            set -euo pipefail
            rm -f /usr/local/bin/listlogs31 /root/listlogs31.out
            mkdir -p /opt/lab31
            rm -f /opt/lab31/*
            echo 'a' > /opt/lab31/app.log
            echo 'b' > /opt/lab31/messages.log
            echo 'c' > /opt/lab31/readme.txt
