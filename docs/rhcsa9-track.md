# RHCSA 9 Track

RHCSA 9 is the legacy RHEL 9 practice track. It keeps the original lab and mock exam set stable on a RHEL 9-compatible baseline.

## Runtime

Use the RHCSA 9 profile when training against the RHEL 9 objective set:

```powershell
.\RHCSA.ps1 profile RHCSA9
.\RHCSA.ps1 up
```

Provide an x86_64 RHEL 9 DVD ISO for this track. The simulator accepts same-major DVD ISO filenames that match `rhel-9.*-x86_64-dvd.iso`, such as `rhel-9.8-x86_64-dvd.iso`.

RHEL ISO downloads require a Red Hat account. Use the official Red Hat Developer downloads page and choose the x86_64 DVD ISO, not the boot ISO:

```text
https://developers.redhat.com/products/rhel/download#downloadsbyrelease
```

If multiple RHEL 9 DVD ISOs are present, the simulator uses the newest matching file. Set `RHCSA_ISO` when you want to keep the ISO outside the project folder or force a specific ISO:

```powershell
$env:RHCSA_ISO = "C:\path\to\rhel-9.8-x86_64-dvd.iso"
.\RHCSA.ps1 up
```

Recommended: import the package repository cache once, then run future baselines from `.rhcsa-repo/` without keeping the ISO in the project root:

```powershell
.\RHCSA.ps1 repo import C:\path\to\rhel-9.8-x86_64-dvd.iso
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

Run live replay from Windows PowerShell because the verifier talks to the Windows Vagrant and VirtualBox environment:

```powershell
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA9
<python> .\host\verify_scenario_solutions.py --kind exam --track RHCSA9
```

For fast static checks:

```powershell
<python> .\tools\scenarios\audit_scenarios.py
<python> .\host\verify_scenario_solutions.py --kind all --track RHCSA9 --audit-only
```

Replace `<python>` with the Python launcher available on your machine, such as `python`, `python3.13.exe`, or `py -3.13`. Use `--only <scenario-id>` for focused checks, for example:

```powershell
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA9 --only lab-15-lvm-create-mount --audit-only
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA9 --only lab-15-lvm-create-mount
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
