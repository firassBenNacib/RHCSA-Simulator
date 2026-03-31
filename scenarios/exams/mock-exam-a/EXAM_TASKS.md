# Mock Exam A: Access And Service Integration - Exam Tasks
Scenario ID: mock-exam-a
Mode: Exam
Time limit: 120 minutes
Objectives: networking-and-firewall, software-scheduling-time, filesystems-and-autofs, users-sudo-ssh

A redesigned RHCSA v9 mock exam focused on time sync, service networking, automounts, remote access, and delegated administration.

## Task 01 - Chrony Client (clientvm) - 20 pts
Configure chrony to synchronize only with servervm and ensure chronyd is enabled.

## Task 02 - Edge Network And Apache (clientvm) - 20 pts
Set the persistent hostname to clientvm.edge.lab, add a hostname-resolution entry for internal-api.edge.lab to 192.168.122.3, make Apache listen on port 8088, open 8088/tcp in the firewall, and add a persistent route for 203.0.113.0/24 via 192.168.122.3.

## Task 03 - NFS Mount And Autofs Map (clientvm) - 20 pts
Create a persistent NFS mount for servervm:/exports/direct at /srv/reference and configure autofs so /research/field-guide/brief.txt is available on demand.

## Task 04 - Orchid Delegated Administration (clientvm) - 20 pts
Create group platformops and user orchid, authorize admin's SSH public key for orchid, and allow platformops to run systemctl restart httpd with sudo and no password.

## Task 05 - SSH File Transfer (clientvm) - 20 pts
Copy /srv/rhcsa/objectives/README.txt from servervm to /home/orchid/edge-brief.txt using SSH-based file transfer and leave orchid owning the file.
