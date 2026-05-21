# Release Process

The repository publishes source through git and TUI binaries through GitHub Releases. Built `.exe`, Linux, and macOS binaries are release assets, not source-controlled files.

## Normal Release

Release Please opens a release PR from `main`. Merging that PR creates the semantic version tag and GitHub Release. The tag starts the GoReleaser workflow, which attaches the TUI archives and checksums.

For a manual release, ensure CI is green and create a semantic version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `release-tui` workflow runs GoReleaser on tag pushes. It creates archives for Windows, Linux, and macOS, attaches checksums, smoke-tests the Linux binary with `--version`, and generates the release changelog from commits.

## Snapshot Build

Use the manual `Release TUI` workflow or run locally:

```bash
goreleaser release --snapshot --clean
```

Snapshot builds are for testing artifacts only. They are uploaded as workflow artifacts, not published as stable release assets.

## Installer

Windows users can install the latest release TUI binary with:

```powershell
irm https://raw.githubusercontent.com/firassBenNacib/rhcsa_exam_vms/main/install.ps1 | iex
```

The installer supports both the older raw `rhcsa-tui-windows-amd64.exe` release asset and the GoReleaser `rhcsa-tui_*_windows_amd64.zip` archive.
