# RHCSA 10 Track Plan

RHCSA 10 content is a separate track from the validated RHCSA 9 corpus. Existing RHCSA 9 scenarios stay tagged with `tracks: ["rhcsa9"]` and `rhel_major: 9`; new RHEL 10-specific scenarios should use `tracks: ["rhcsa10"]` and `rhel_major: 10`.

## Why It Is Separate

Red Hat currently lists EX200 as based on RHEL 10. The public objectives include Flatpak repository and package management, and they also include scheduling tasks with `at`, `cron`, and systemd timer units. Those changes should not be mixed into RHCSA 9 labs because the validated replay baseline and package assumptions are different.

Rocky Linux 10 is useful as a compatible community profile, but its AMD/Intel builds require x86-64-v3. The simulator validates that CPU capability before starting a `rhel10` profile on Linux hosts so users do not fail later during provisioning.

The default Vagrant box for the preview `rhel10` profile is `rockylinux/10`. Keep `RHCSA_BOX` as an override for users who maintain a local RHEL 10 or Rocky 10 box.

## Initial Coverage Matrix

| Area | RHCSA 9 Status | RHCSA 10 Direction |
|---|---:|---|
| RPM repositories and packages | covered | keep, update package names only when needed |
| Flatpak repositories and packages | not in RHCSA 9 | preview lab added for system remote setup |
| systemd timers | partial service coverage | preview lab added for service/timer unit creation |
| NetworkManager DHCP changes | generic networking covered | keep tasks focused on `nmcli` and avoid removed legacy DHCP packages |
| storage, SELinux, users, SSH, logs | covered | reuse where behavior remains compatible |
| containers | RHCSA 9 track only for now | keep separate until RHCSA 10 objectives are validated against the runtime |

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
