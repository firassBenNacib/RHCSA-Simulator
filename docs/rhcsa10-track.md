# RHCSA 10 Track

RHCSA 10 is the default simulator track for new checkouts. It uses a RHEL 10-compatible baseline and keeps newer objectives out of the RHCSA 9 catalog.

## Runtime

Use the RHCSA 10 profile when training against the RHEL 10 objective set:

```powershell
.\RHCSA.ps1 profile RHCSA10
.\RHCSA.ps1 up
```

Provide an x86_64 RHEL 10 DVD ISO for this track. The simulator accepts same-major DVD ISO filenames that match `rhel-10.*-x86_64-dvd.iso`, such as `rhel-10.2-x86_64-dvd.iso`.

RHEL ISO downloads require a Red Hat account. Use the official Red Hat Developer downloads page and choose the x86_64 DVD ISO, not the boot ISO:

```text
https://developers.redhat.com/products/rhel/download#downloadsbyrelease
```

If multiple RHEL 10 DVD ISOs are present, the simulator uses the newest matching file. Set `RHCSA_ISO` when you want to keep the ISO outside the project folder or force a specific ISO:

```powershell
$env:RHCSA_ISO = "C:\path\to\rhel-10.2-x86_64-dvd.iso"
.\RHCSA.ps1 up
```

Recommended: import the package repository cache once, then run future baselines from `.rhcsa-repo/` without keeping the ISO in the project root:

```powershell
.\RHCSA.ps1 repo import C:\path\to\rhel-10.2-x86_64-dvd.iso
.\RHCSA.ps1 up
```

The default Vagrant box is `boxomatic/almalinux-10`. Advanced users can override it with `RHCSA_BOX` and `RHCSA_BOX_URL`.

## Catalog

The RHCSA 10 catalog contains 48 labs and 8 mock exams:

```text
scenarios/labs/rhcsa10/
scenarios/exams/rhcsa10/
```

Coverage includes:

- RPM repositories
- Flatpak remotes
- Flatpak application lifecycle
- systemd timers
- NetworkManager
- storage
- SELinux
- users and groups
- sudo
- SSH
- logs
- services
- scheduling
- boot recovery
- client/server administration

RHCSA 10 keeps RHEL 10-specific topics in this track. RHCSA 9 Podman/container tasks should not be moved into RHCSA 10 unless they are deliberately tested and marked as compatible.

The mock exams are client/server exams. Individual questions may target the client VM, the server VM, or both systems, but each exam requires both VMs.

## Verification

Run live replay from Windows PowerShell because the verifier talks to the Windows Vagrant and VirtualBox environment:

```powershell
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA10
<python> .\host\verify_scenario_solutions.py --kind exam --track RHCSA10
```

For fast static checks:

```powershell
<python> .\tools\scenarios\audit_scenarios.py
<python> .\host\verify_scenario_solutions.py --kind all --track RHCSA10 --audit-only
```

Replace `<python>` with the Python launcher available on your machine, such as `python`, `python3.13.exe`, or `py -3.13`. Use `--only <scenario-id>` for focused checks, for example:

```powershell
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA10 --only lab-06-flatpak-remote --audit-only
<python> .\host\verify_scenario_solutions.py --kind lab --track RHCSA10 --only lab-06-flatpak-remote
```

Live replay is the source of truth after changes to:

- provisioning
- checks
- scenario setup
- scenario solutions
- package assumptions
- storage behavior
- networking behavior
- Flatpak behavior
- systemd timer behavior

## Authoring

RHCSA 10 scenarios should use:

```json
{
  "tracks": ["rhcsa10"],
  "rhel_major": 10
}
```

Use RHCSA 10-specific scenario IDs and keep the wording original.

Regenerate RHCSA 10 scenarios from:

```text
tools/scenarios/generate_rhcsa10_scenarios.py
```

Generated manifests should be changed through the generator when possible so future regeneration stays reproducible.

A scenario should only be marked as dual-track when it has been tested and verified on both RHCSA 9 and RHCSA 10 baselines.
