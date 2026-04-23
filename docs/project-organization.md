# Project Organization

## Current Shape

The simulator has three public surfaces:

* `RHCSA.ps1` for users.
* `cmd/rhcsa-tui` for the terminal UI source.
* `tools/scenarios` for scenario tooling commands.

The implementation is intentionally split between PowerShell orchestration, Go TUI code, Python scenario tools, and guest shell provisioning. This is normal for a VM-based lab simulator, but large files should keep shrinking behind stable entrypoints.

## Scenario Directory Layout

Scenarios are organized into track-specific subdirectories:

```
scenarios/
  labs/
    rhcsa9/     # 48 RHCSA 9 labs
    rhcsa10/    # 48 RHCSA 10 labs
  exams/
    rhcsa9/     # 8 RHCSA 9 mock exams
    rhcsa10/    # 8 RHCSA 10 mock exams
```

Each scenario directory contains `scenario.json`, `LAB_TASKS.md`/`EXAM_TASKS.md`, `LAB_SOLUTION.md`/`EXAM_SOLUTION.md`, and any guest provisioning scripts. Scenario IDs are unique within a track (e.g., both `rhcsa9/` and `rhcsa10/` can have `mock-exam-a`), so progress tracking uses composite `track/id` keys.

## PowerShell Modules

The PowerShell host code is split into focused `.psm1` modules under `host/modules/`:

| Module | Responsibility |
|---|---|
| FileHelpers | File I/O, UTF-8 no-BOM writes |
| UI | Console formatting, colors |
| LabState | Active-run state, progress JSON |
| Scenarios | Catalog loading, manifest parsing |
| Toolchain | Vagrant/VirtualBox path resolution |
| VMControl | VM lifecycle, SSH, interactive commands |
| Checks | Lab check execution and scoring |

## Recommended Direction

Keep `RHCSA.ps1` as a small facade over focused PowerShell modules. The modules live under `host/modules/` and are imported by `host/modules/RhcsaSimulator`.

Keep Python implementation in `tools/scenarios/`. Host orchestration should stay in PowerShell; Python tooling should not be mixed back into `host/`.

Keep Go package tests beside package source. In Go, colocated `*_test.go` files are idiomatic. A separate `tests/` directory should only be used for end-to-end flows, fixtures, or black-box integration tests that span multiple packages.

## Comparison Notes

AustinNicely's `rhcsa-simulator` is a Python-first, single-host simulator with generated task categories, validators, progress tracking, an installer, `requirements.txt`, and `pytest.ini`. This project is a VM-first simulator, so the architecture should not be copied directly, but several ideas are useful:

* keep validators and scenario tooling modular
* provide local developer commands for repeatable checks
* keep Python tests in CI
* document installation and extension paths clearly
* keep release assets out of git and publish them through GitHub Releases

Those ideas map here to `tools/scenarios`, `Makefile`, Python unit tests in CI, GoReleaser release packaging, and PowerShell orchestration under `host/`.

## RHCSA 10 Track

RHCSA 10 support stays separate from RHCSA 9. The RHCSA 10 catalog now contains 48 labs and 8 mock exams generated from original scenario definitions, with Flatpak, systemd timers, RHEL 10 software management, NetworkManager, storage, SELinux, users, logging, and scheduling coverage.

The content is audit-validated. Full runtime validation still depends on a local RHEL 10-compatible baseline because GitHub-hosted runners cannot run the VirtualBox/RHEL ISO environment used by the simulator.

Do not copy tasks from exam dumps or proprietary PDFs. Use those materials only as a coverage-gap signal.
