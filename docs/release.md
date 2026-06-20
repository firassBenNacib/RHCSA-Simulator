# Release Process

This document explains how RHCSA Simulator releases are created and how TUI binaries are published.

The repository publishes source code through git and prebuilt TUI binaries through GitHub Releases.

Built binaries are release assets. They should not be committed to the repository.

## Release Outputs

A normal release publishes:

- a semantic version tag
- a GitHub Release
- Windows, Linux, and macOS TUI archives
- checksums
- a generated changelog

The Go TUI source remains under:

```text
cmd/rhcsa-tui/
```

Shared Go packages remain under:

```text
internal/
```

Generated binaries should stay outside git.

## Normal Release

Release Please opens a release pull request from `main`.

Merging the Release Please pull request creates:

- the semantic version tag
- the GitHub Release
- the release changelog

The tag then starts the GoReleaser workflow, which builds and uploads the TUI archives.

## Manual Release

Use a manual release only when Release Please is not suitable.

Before creating a manual tag, make sure CI is green:

```bash
git status
git pull
```

Create and push a semantic version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `release-tui` workflow runs automatically on tag pushes.

It builds release archives for:

```text
windows/amd64
linux/amd64
darwin/amd64
darwin/arm64
```

It also attaches checksums and runs a basic smoke test against the Linux binary with:

```bash
--version
```

## Snapshot Build

Snapshot builds are used to test release artifacts without publishing a stable release.

Run locally:

```bash
goreleaser release --snapshot --clean
```

Or use the manual `Release TUI` workflow in GitHub Actions.

Snapshot artifacts are for testing only. They are uploaded as workflow artifacts and are not considered stable release assets.

## Installer

Windows users can install the latest release TUI binary with:

```powershell
irm https://raw.githubusercontent.com/firassBenNacib/RHCSA-Simulator/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

This is the recommended method because the installer is downloaded as a file before execution.

The installer downloads the latest Windows TUI release archive, extracts `rhcsa-tui.exe`, and places it under the local build output path used by the project.

The installer supports:

- the older raw `rhcsa-tui-windows-amd64.exe` release asset
- the GoReleaser `rhcsa-tui_*_windows_amd64.zip` archive

## Release Asset Policy

Do not commit release binaries to git.

The repository should not contain:

```text
rhcsa-tui.exe
rhcsa-tui
*.zip release archives
*.tar.gz release archives
checksums.txt
dist/
.build/
```

Release assets belong in GitHub Releases.

Local generated files should remain ignored by git.

## Versioning

Use semantic version tags:

```text
vMAJOR.MINOR.PATCH
```

Examples:

```text
v1.0.0
v1.1.0
v1.1.1
```

Use version changes as follows:

| Version type | Use when |
|---|---|
| `MAJOR` | Breaking CLI, scenario, or release behavior |
| `MINOR` | New features, tracks, commands, or major scenario additions |
| `PATCH` | Fixes, documentation updates, small improvements |

## Pre-Release Checklist

Before releasing:

```bash
make test
```

Also run the main Windows checks when changing PowerShell, scenarios, or release behavior:

```powershell
go test ./...
go vet ./...
go build ./cmd/rhcsa-tui
<python> -m unittest discover tools/scenarios/tests
<python> .\host\verify_scenario_solutions.py --kind all --track all --audit-only
<python> .\tools\scenarios\audit_scenarios.py
```

Replace `<python>` with the Python launcher available on your machine, such as `python`, `python3.13.exe`, or `py -3.13`.

For runtime, provisioning, or scenario solution changes, run live replay locally before publishing a release.

## Post-Release Checklist

After a release is published:

1. Open the GitHub Release page.
2. Confirm the TUI archives were uploaded.
3. Confirm checksums were uploaded.
4. Download the Windows archive.
5. Run the installer on a clean local checkout.
6. Start the TUI:

```powershell
.\RHCSA.ps1 tui
```

7. Confirm the version output works:

```powershell
.\.build\rhcsa-tui.exe --version
```

## Failure Handling

If a release workflow fails:

1. Check the failed GitHub Actions job.
2. Fix the workflow, GoReleaser config, or build issue.
3. Re-run the failed workflow if the tag is still valid.
4. If the tag should not be used, delete the failed tag and create a new patch release.

Delete a local tag:

```bash
git tag -d v1.0.0
```

Delete a remote tag:

```bash
git push origin :refs/tags/v1.0.0
```

Then create a corrected release tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## Related Files

Release behavior is mainly controlled by:

```text
.github/workflows/release-please.yml
.github/workflows/release-tui.yml
.goreleaser.yml
install.ps1
```
