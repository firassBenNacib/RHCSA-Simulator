# RHCSA 9 Track

RHCSA 9 is the default simulator track and the stable baseline for the original lab and mock exam corpus. It stays separate from RHCSA 10 so Podman-era objectives, package names, and RHEL 9 service behavior remain reproducible.

## Runtime Baseline

The RHCSA 9 profile uses the local `rhel-9.7-x86_64-dvd.iso` as the offline package source and the RHCSA 9 scenario catalog:

```powershell
.\RHCSA.ps1 profile RHCSA9
.\RHCSA.ps1 up
```

The track contains 48 labs and 8 mock exams under:

```text
scenarios/labs/rhcsa9/
scenarios/exams/rhcsa9/
```

## Coverage

RHCSA 9 covers the expected core simulator areas: boot recovery, DNF repositories, networking, users and groups, sudo, SELinux, firewalld, storage, NFS/autofs, cron/at, logs, tuned, SSH, archives, find/grep, and Podman/container administration.

RHCSA 10-only objectives such as Flatpak and systemd timer tasks belong in the RHCSA 10 track unless a scenario is deliberately proven on both profiles.

## Verification

Use Windows Python for live replay because the verifier talks to the Windows Vagrant and VirtualBox environment:

```powershell
.\RHCSA.ps1 profile RHCSA9
.\RHCSA.ps1 up
python3.13.exe .\host\verify_scenario_solutions.py --kind lab --track RHCSA9
python3.13.exe .\host\verify_scenario_solutions.py --kind exam --track RHCSA9
```

Full live replay for RHCSA 9 labs and exams has passed on the supported local Windows + VirtualBox workflow.

## Authoring Rules

Use original wording and keep RHCSA 9 scenarios tagged for the RHCSA 9 runtime:

```json
{
  "tracks": ["rhcsa9"],
  "rhel_major": 9
}
```

Only mark a scenario as dual-track after it passes audit validation and live replay on both RHCSA 9 and RHCSA 10 baselines.
