# Essential Tools And File Workflows - Lab Solution
Scenario ID: essential-tools
Mode: Lab
Time limit: 45 minutes
Objectives: essential-tools

Practice core RHCSA v9 command-line file operations, archives, links, permissions, and text processing.

## Task 01 - Backup Archive (clientvm) - 10 pts
```bash
cd /opt/rhcsa/workspaces
tar -czf /root/essential-tools-backup.tar.gz essential-tools
```

## Task 02 - Hard And Symbolic Links (clientvm) - 10 pts
```bash
cd /opt/rhcsa/workspaces/essential-tools
ln data/report.txt report.hardlink
ln -s data/report.txt report.symlink
ls -li data/report.txt report.hardlink report.symlink
```

## Task 03 - Error Log Extraction (clientvm) - 10 pts
```bash
cd /opt/rhcsa/workspaces/essential-tools
grep 'ERROR' logs/app.log > /root/errors-only.log
```

## Task 04 - Secure Directory Permissions (clientvm) - 10 pts
```bash
cd /opt/rhcsa/workspaces/essential-tools
chgrp adm secure
chmod 2770 secure
```

## Task 05 - Configuration File Count (clientvm) - 10 pts
```bash
cd /opt/rhcsa/workspaces/essential-tools
find data -type f -name '*.conf' | wc -l | tr -d ' ' > /root/conf-count.txt
```

## Task 06 - Tar Gzip Long Option (clientvm) - 10 pts
```bash
man tar | col -b | grep -m1 -o -- '--gzip' > /root/tar-doc-answer.txt
```

Verification
```bash
ls -l /root/essential-tools-backup.tar.gz /opt/rhcsa/workspaces/essential-tools/data/report.txt
ls -ld /opt/rhcsa/workspaces/essential-tools/secure
cat /root/errors-only.log
cat /root/conf-count.txt
cat /root/tar-doc-answer.txt
```
