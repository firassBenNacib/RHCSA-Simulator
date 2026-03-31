# Mock Exam A: Access And Service Integration - Lab Tasks
Scenario ID: mock-exam-a
Mode: Lab
Time limit: 120 minutes
Objectives: networking-and-firewall, software-scheduling-time, filesystems-and-autofs, users-sudo-ssh

A redesigned RHCSA v9 mock exam focused on time sync, service networking, automounts, remote access, and delegated administration.

## Task 01 - Chrony Client (clientvm) - 20 pts
Configure chrony so clientvm synchronizes only with servervm and ensure chronyd is enabled.

## Task 02 - Edge Network And Apache (clientvm) - 20 pts
Set the persistent hostname to clientvm.edge.lab, add a hostname-resolution entry so internal-api.edge.lab resolves to 192.168.122.3, configure Apache to listen on port 8088, open the firewall for 8088/tcp, and add a persistent route for 203.0.113.0/24 via 192.168.122.3.

## Task 03 - NFS Mount And Autofs Map (clientvm) - 20 pts
Create a persistent NFS mount for servervm:/exports/direct at /srv/reference and configure autofs so /research/field-guide/brief.txt becomes available on demand from servervm.

## Task 04 - Orchid Delegated Administration (clientvm) - 20 pts
Create group platformops and user orchid with platformops as the primary group, authorize admin's SSH public key for orchid, and allow members of platformops to run systemctl restart httpd with sudo and no password.

## Task 05 - SSH File Transfer (clientvm) - 20 pts
As admin on clientvm, copy /srv/rhcsa/objectives/README.txt from servervm to /home/orchid/edge-brief.txt using SSH-based file transfer and leave orchid owning the file.

Hints
1. chronyd should point only at servervm in this exam.
2. Use a persistent hostname-resolution method for internal-api.edge.lab.
3. The autofs path is an indirect map under /research, while /srv/reference is a normal persistent mount.
4. Use the existing admin SSH key as the key source for orchid.
5. servervm already accepts the baseline admin account over SSH, so scp is enough for the transfer task.

Checks
```bash
chronyc sources -v
hostnamectl status --static
getent hosts internal-api.edge.lab
ip route show
curl http://localhost:8088/
findmnt /srv/reference
ls -l /research/field-guide/brief.txt
sudo -l -U orchid
ls -l /home/orchid/edge-brief.txt
```
