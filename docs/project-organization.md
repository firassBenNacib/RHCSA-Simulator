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

## RHCSA 10 Track

RHCSA 10 support should stay separate from RHCSA 9 until replay is validated on a RHEL 10-compatible baseline. The first RHCSA 10 preview labs cover Flatpak remote setup and systemd timers. Next additions should focus on RHEL 10 software-management changes and NetworkManager/Rocky 10 differences.

Do not copy tasks from exam dumps or proprietary PDFs. Use those materials only as a coverage-gap signal.
