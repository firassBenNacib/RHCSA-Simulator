# Essential Tools And File Workflows - Lab Tasks
Scenario ID: essential-tools
Mode: Lab
Time limit: 45 minutes
Objectives: essential-tools

Practice core RHCSA v9 command-line file operations, archives, links, permissions, and text processing.

## Task 01 - Backup Archive (clientvm) - 10 pts
Work in /opt/rhcsa/workspaces/essential-tools and create a tar.gz archive of the source tree named /root/essential-tools-backup.tar.gz.

## Task 02 - Hard And Symbolic Links (clientvm) - 10 pts
Create one hard link and one symbolic link to the file data/report.txt and demonstrate that both resolve correctly.

## Task 03 - Error Log Extraction (clientvm) - 10 pts
Use shell redirection and grep to create /root/errors-only.log containing only the lines with the word ERROR from logs/app.log.

## Task 04 - Secure Directory Permissions (clientvm) - 10 pts
Set permissions so the directory secure is accessible by root and members of the adm group only, with group collaboration enabled on new files.

## Task 05 - Configuration File Count (clientvm) - 10 pts
Use one command-line text-processing workflow to count how many files under data end with .conf and save the numeric result to /root/conf-count.txt.

## Task 06 - Tar Gzip Long Option (clientvm) - 10 pts
Use system documentation to identify the tar long option for gzip compression and write only that option to /root/tar-doc-answer.txt.

Hints
1. The workspace is already seeded for you. Focus on command-line operations, not package installs.
2. The secure directory task is about ownership, permissions, and the setgid bit.
3. A pipeline using grep, find, wc, sort, or awk is acceptable for the count task.
4. You can use man, info, or files under /usr/share/doc for the documentation task.

Checks
```bash
ls -l /root/essential-tools-backup.tar.gz /opt/rhcsa/workspaces/essential-tools/data/report.txt
ls -ld /opt/rhcsa/workspaces/essential-tools/secure
cat /root/errors-only.log
cat /root/conf-count.txt
cat /root/tar-doc-answer.txt
```
