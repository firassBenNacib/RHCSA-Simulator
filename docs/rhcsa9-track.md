# RHCSA 9 Track

RHCSA 9 is the default simulator track. It keeps the original lab and mock exam set stable on a RHEL 9-compatible baseline.

## Runtime

Use the RHCSA 9 profile when training against the RHEL 9 objective set:

```powershell
.\RHCSA.ps1 profile RHCSA9
.\RHCSA.ps1 up
```

Place an x86_64 RHEL 9 DVD ISO in the project root. The simulator accepts same-major DVD ISO filenames that match `rhel-9.*-x86_64-dvd.iso`, such as `rhel-9.8-x86_64-dvd.iso`.

RHEL ISO downloads require a Red Hat account. Use the official Red Hat Developer downloads page and choose the x86_64 DVD ISO, not the boot ISO:

```text
https://developers.redhat.com/products/rhel/download#downloadsbyrelease
```

If multiple RHEL 9 DVD ISOs are present, the simulator uses the newest matching file. Set `RHCSA_ISO` when you want to force a specific ISO:

```powershell
$env:RHCSA_ISO = "C:\path\to\rhel-9.8-x86_64-dvd.iso"
.\RHCSA.ps1 up
```

## Catalog

The RHCSA 9 catalog contains 48 labs and 8 mock exams:

```text
scenarios/labs/rhcsa9/
scenarios/exams/rhcsa9/
```

Coverage includes:

- networking
- DNF repositories
- users and groups
- sudo
- SELinux
- firewalld
- storage
- NFS and autofs
- cron and at
- logs
- tuned
- SSH
- archives
- find and grep
- boot recovery
- Podman/container tasks

RHCSA 9 keeps Podman/container practice in this track. RHCSA 10-specific topics such as Flatpak and systemd timers belong in the RHCSA 10 track.

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

Live replay is the source of truth after changes to:

- provisioning
- checks
- scenario setup
- scenario solutions
- package assumptions
- storage behavior
- networking behavior

## Authoring

RHCSA 9 scenarios should use:

```json
{
  "tracks": ["rhcsa9"],
  "rhel_major": 9
}
```

Use RHCSA 9-specific scenario IDs and keep the wording original.

A scenario should only be marked as dual-track when it has been tested and verified on both RHCSA 9 and RHCSA 10 baselines.
