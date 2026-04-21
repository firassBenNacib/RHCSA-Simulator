# Project Organization

## Current Shape

The simulator has three public surfaces:

* `RHCSA.ps1` for users.
* `cmd/rhcsa-tui` for the terminal UI source.
* `host/*.py` wrappers for existing scenario tooling commands.

The implementation is intentionally split between PowerShell orchestration, Go TUI code, Python scenario tools, and guest shell provisioning. This is normal for a VM-based lab simulator, but large files should keep shrinking behind stable entrypoints.

## Recommended Direction

Keep `RHCSA.ps1` as a small facade over focused PowerShell modules:

* catalog and scenario state
* Vagrant and VirtualBox lifecycle
* SSH helpers
* baseline recovery
* cleanup
* output formatting
* TUI launcher

Keep Python implementation in `tools/scenarios/`. The `host/*.py` files should remain as compatibility wrappers for one release, then can be deprecated after documentation and CI call the `tools` entrypoints directly.

Keep Go package tests beside package source. In Go, colocated `*_test.go` files are idiomatic. A separate `tests/` directory should only be used for end-to-end flows, fixtures, or black-box integration tests that span multiple packages.

## Comparison Notes

AustinNicely's `rhcsa-simulator` is a Python-first, single-host simulator with generated task categories, validators, progress tracking, an installer, `requirements.txt`, and `pytest.ini`. This project is a VM-first simulator, so the architecture should not be copied directly, but several ideas are useful:

* keep validators and scenario tooling modular
* provide local developer commands for repeatable checks
* keep Python tests in CI
* document installation and extension paths clearly
* keep release assets out of git and publish them through GitHub Releases

Those ideas map here to `tools/scenarios`, `Makefile`, Python unit tests in CI, GoReleaser release packaging, and compatibility wrappers under `host/`.

## RHCSA 10 Track

RHCSA 10 support stays separate from RHCSA 9. The RHCSA 10 catalog now contains 48 labs and 8 mock exams generated from original scenario definitions, with Flatpak, systemd timers, RHEL 10 software management, NetworkManager, storage, SELinux, users, logging, and scheduling coverage.

The content is audit-validated. Full runtime validation still depends on a local RHEL 10-compatible baseline because GitHub-hosted runners cannot run the VirtualBox/RHEL ISO environment used by the simulator.

Do not copy tasks from exam dumps or proprietary PDFs. Use those materials only as a coverage-gap signal.
