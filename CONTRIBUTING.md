# Contributing

This project is a Windows-first RHCSA lab simulator with portable source builds where practical. Keep the public commands stable:

```powershell
.\RHCSA.ps1 up
.\RHCSA.ps1 tui
python host/verify_scenario_solutions.py --kind all --audit-only
```

## Repository Layout

* `RHCSA.ps1` is the user-facing PowerShell entrypoint.
* `host/` contains host orchestration and compatibility wrappers.
* `tools/scenarios/` contains scenario authoring, audit, smoke, and replay tooling.
* `cmd/rhcsa-tui/` contains the Go terminal UI source.
* `internal/` contains shared Go packages for the TUI.
* `scenarios/labs/` and `scenarios/exams/` contain the authored scenario corpus.
* `guest/` contains provisioning scripts that run inside the VMs.

The `host/*.py` files are compatibility wrappers for existing automation. New Python implementation code should go under `tools/scenarios/`, preferably inside the `rhcsa_scenarios` package.

Keep `cmd/rhcsa-tui`, `internal`, `tools`, workflows, docs, and scenario sources tracked. Do not commit `.build/`, `.vagrant/`, ISO files, runtime state, or compiled binaries.

## Tests And Checks

Run the fast checks before opening a PR:

```bash
make test
```

On Windows PowerShell, run the equivalent commands directly:

```powershell
go test ./...
go vet ./...
go build ./cmd/rhcsa-tui
python host/verify_scenario_solutions.py --kind all --audit-only
python host/verify_scenario_solutions.py --kind all --track all --audit-only
python tools/scenarios/audit_scenarios.py
python -m unittest discover tools/scenarios/tests
vagrant validate
```

PowerShell files should parse cleanly and should not introduce PSScriptAnalyzer warnings.

Release packaging is handled by GoReleaser. Use `goreleaser release --snapshot --clean` for a local snapshot build when GoReleaser is installed.

## Generated And Local Files

Do not commit VM state, ISOs, local caches, or built binaries. The ignored local paths include `.build/`, `.lab-state/`, `.lab-disks/`, `.vagrant/`, `__pycache__/`, `*.pyc`, `*.iso`, and generated TUI executables.

## Scenario Rules

Use original wording. Public objectives can guide topic coverage, but do not copy exam dumps, commercial course text, or proprietary task wording into this repository.

RHCSA 9 scenarios stay tagged with:

```json
{
  "tracks": ["rhcsa9"],
  "rhel_major": 9
}
```

RHCSA 10-specific scenarios must use:

```json
{
  "tracks": ["rhcsa10"],
  "rhel_major": 10
}
```

Only mark a scenario as dual-track after audit-only validation and runtime replay pass on both baselines.
