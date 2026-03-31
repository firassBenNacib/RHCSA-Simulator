# Mock Exam B: System Review And Hardening - Exam Tasks
Scenario ID: mock-exam-b
Mode: Exam
Time limit: 120 minutes
Objectives: storage-lvm, processes-logs-tuning, selinux-and-default-perms, essential-tools

A redesigned RHCSA v9 mock exam focused on local storage, default permissions, SELinux labeling and port control, process tuning, logging, and file workflows.

## Task 01 - LVM Storage Layout (clientvm) - 20 pts
Create volume group opsdata_vg with an XFS logical volume records mounted at /srv/records, an ext4 logical volume archive mounted at /mnt/archive, and a 256 MiB swap logical volume named reviewswap activated persistently.

## Task 02 - Default Permissions (clientvm) - 20 pts
Set the system-wide default umask to 027 and make /srv/reports collaborative for group reviewers only, with setgid for new files.

## Task 03 - Apache With SELinux (clientvm) - 20 pts
Make Apache serve /srv/rhcsa/review-site/index.html at http://localhost:8089/ while SELinux remains enforcing, apply persistent file and port labeling, set httpd_can_network_connect persistently to on, and ensure the service starts at boot.

## Task 04 - Processes Logs And Tuning (clientvm) - 20 pts
Lower the priority of the seeded busy process, persist the journal, activate throughput-performance, and enable and start review-stamp.service.

## Task 05 - Archive And Log Filtering (clientvm) - 20 pts
Create /root/reports-bundle.tar.gz from /srv/reports and write only the ALERT lines from /opt/rhcsa/workspaces/review-material/alerts.log to /root/alerts-only.log.
