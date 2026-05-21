# RHCSA 9 Track

RHCSA 9 is the default simulator track. It keeps the original lab and mock exam set stable on a RHEL 9-compatible baseline.

## Runtime

Use the RHCSA 9 profile when training against the RHEL 9 objective set:

```powershell
.\RHCSA.ps1 profile RHCSA9
.\RHCSA.ps1 up
```

The profile uses `rhel-9.7-x86_64-dvd.iso` in the project root as the offline package source.

## Catalog

The RHCSA 9 catalog contains 48 labs and 8 mock exams:

```text
scenarios/labs/rhcsa9/
scenarios/exams/rhcsa9/
```

Coverage includes networking, DNF repositories, users and groups, sudo, SELinux, firewalld, storage, NFS/autofs, cron/at, logs, tuned, SSH, archives, find/grep, boot recovery, and Podman/container tasks.

## Verification

Use Windows Python for live replay because the verifier talks to the Windows Vagrant and VirtualBox environment:

```powershell
python3.13.exe .\host\verify_scenario_solutions.py --kind lab --track RHCSA9
python3.13.exe .\host\verify_scenario_solutions.py --kind exam --track RHCSA9
```

For a fast metadata-only check:

```powershell
python3.13.exe .\host\verify_scenario_solutions.py --kind all --track RHCSA9 --audit-only
```

## Authoring

RHCSA 9 scenarios should use:

```json
{
  "tracks": ["rhcsa9"],
  "rhel_major": 9
}
```

Keep RHCSA 10-only topics such as Flatpak and systemd timers in the RHCSA 10 track unless a scenario is deliberately tested and marked as dual-track.
