# RHCSA 10 Track

RHCSA 10 content is a separate track from the validated RHCSA 9 corpus. Existing RHCSA 9 scenarios stay tagged with `tracks: ["rhcsa9"]` and `rhel_major: 9`; new RHEL 10-specific scenarios should use `tracks: ["rhcsa10"]` and `rhel_major: 10`.

## Why It Is Separate

Red Hat currently lists EX200 as based on RHEL 10. The public objectives include Flatpak repository and package management, and they also include scheduling tasks with `at`, `cron`, and systemd timer units. Those changes should not be mixed into RHCSA 9 labs because the validated replay baseline and package assumptions are different.

AlmaLinux 10 and Rocky Linux 10 are useful compatible community profiles, but RHEL-compatible 10 AMD/Intel builds can require newer x86-64 feature levels. The simulator validates x86-64-v3 capability before starting a `rhel10` profile on Linux hosts so users do not fail later during provisioning.

The default Vagrant box for the `rhel10` profile is `boxomatic/almalinux-10`, which boots reliably on the supported Windows + VirtualBox workflow. Keep `RHCSA_BOX`, `RHCSA_BOX_VERSION`, and `RHCSA_BOX_URL` as overrides for users who maintain an AlmaLinux, Rocky Linux 10, RHEL 10, or custom pre-provisioned box.

## Coverage Matrix

| Area | RHCSA 9 Status | RHCSA 10 Direction |
|---|---:|---|
| RPM repositories and packages | covered | keep, update package names only when needed |
| Flatpak repositories and packages | not in RHCSA 9 | covered in RHCSA 10 labs and exams |
| systemd timers | partial service coverage | covered in RHCSA 10 labs and exams |
| NetworkManager DHCP changes | generic networking covered | keep tasks focused on `nmcli` and avoid removed legacy DHCP packages |
| storage, SELinux, users, SSH, logs | covered | reuse where behavior remains compatible |
| containers | RHCSA 9 track only for now | keep separate until RHCSA 10 objectives are validated against the runtime |

The RHCSA 10 content set currently includes 48 labs and 8 mock exams. Full live replay for labs and exams has passed on the supported local Windows + VirtualBox workflow with the RHEL 10 ISO-backed offline repository. CI keeps audit-only checks because hosted runners cannot run the VM environment.

## Verification

Use Windows Python for live replay because the verifier talks to the Windows Vagrant and VirtualBox environment:

```powershell
.\RHCSA.ps1 profile RHCSA10
.\RHCSA.ps1 up
python3.13.exe .\host\verify_scenario_solutions.py --kind lab --track RHCSA10
python3.13.exe .\host\verify_scenario_solutions.py --kind exam --track RHCSA10
```

RHCSA 10 exam IDs use the `rhcsa10-mock-exam-*` prefix so all-track `--only` selection stays unambiguous beside RHCSA 9 mock exams.

## Scenario Authoring Rules

Use original wording. Public objectives can guide topic coverage, but do not copy exam dumps, commercial course text, or proprietary task wording into this repository.

Every new RHCSA 10 scenario should include:

```json
{
  "tracks": ["rhcsa10"],
  "rhel_major": 10
}
```

If a scenario works unchanged on both tracks, use:

```json
{
  "tracks": ["rhcsa9", "rhcsa10"]
}
```

Only mark a scenario as dual-track after it passes audit-only validation and runtime replay on both baselines.
