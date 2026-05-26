# RHCSA 10 Track

RHCSA 10 is a separate simulator track. It uses a RHEL 10-compatible baseline and keeps newer objectives out of the RHCSA 9 catalog.

## Runtime

Use the RHCSA 10 profile when training against the RHEL 10 objective set:

```powershell
.\RHCSA.ps1 profile RHCSA10
.\RHCSA.ps1 up
```

The default validated offline package source is `rhel-10.1-x86_64-dvd.iso` in the project root. Newer RHEL 10 minor DVD ISOs may work, but package sets can differ.

Download RHEL DVD ISOs from [Red Hat Developer downloads by release](https://developers.redhat.com/products/rhel/download#downloadsbyrelease). If Red Hat only lists a newer minor ISO, rename it to the default filename or set `RHCSA_ISO` to the downloaded filename or full path before running `.\RHCSA.ps1 up`.

The default Vagrant box is `boxomatic/almalinux-10`; advanced users can override it with `RHCSA_BOX` and `RHCSA_BOX_URL`.

## Catalog

The RHCSA 10 catalog contains 48 labs and 8 mock exams:

```text
scenarios/labs/rhcsa10/
scenarios/exams/rhcsa10/
```

Coverage includes RPM repositories, Flatpak remotes and application lifecycle, systemd timers, NetworkManager, storage, SELinux, users and groups, sudo, SSH, logs, services, scheduling, and boot recovery.

The mock exams are client/server exams. Individual questions may target client, server, or both systems, but each exam requires both VMs.

## Verification

Use Windows Python for live replay because the verifier talks to the Windows Vagrant and VirtualBox environment:

```powershell
python3.13.exe .\host\verify_scenario_solutions.py --kind lab --track RHCSA10
python3.13.exe .\host\verify_scenario_solutions.py --kind exam --track RHCSA10
```

For a fast metadata-only check:

```powershell
python3.13.exe .\host\verify_scenario_solutions.py --kind all --track RHCSA10 --audit-only
```

## Authoring

RHCSA 10 scenarios should use:

```json
{
  "tracks": ["rhcsa10"],
  "rhel_major": 10
}
```

Regenerate RHCSA 10 scenarios from `tools/scenarios/generate_rhcsa10_scenarios.py`. Generated manifests should be changed through the generator so future regeneration stays reproducible.
