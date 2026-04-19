[CmdletBinding()]
param(
    [string]$Repo = 'firassBenNacib/rhcsa_exam_vms',
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'

function Write-InstallLine {
    param([string]$Message)
    Write-Host "[RHCSA] $Message"
}

function Get-WindowsTuiAsset {
    param([object]$Release)

    $asset = $Release.assets |
        Where-Object { $_.name -match '^rhcsa-tui-windows-amd64\.exe$' } |
        Select-Object -First 1

    if (-not $asset) {
        throw "Release '$($Release.tag_name)' does not include rhcsa-tui-windows-amd64.exe."
    }

    return $asset
}

$projectPath = [System.IO.Path]::GetFullPath($ProjectRoot)
if (-not (Test-Path (Join-Path $projectPath 'RHCSA.ps1') -PathType Leaf)) {
    throw "ProjectRoot must point to the simulator repository that contains RHCSA.ps1. Current value: $projectPath"
}

$buildPath = Join-Path $projectPath '.build'
New-Item -ItemType Directory -Path $buildPath -Force | Out-Null

$releaseUri = "https://api.github.com/repos/$Repo/releases/latest"
$headers = @{ 'User-Agent' = 'rhcsa-simulator-installer' }
if ($env:GITHUB_TOKEN) {
    $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
}

Write-InstallLine "Reading latest release from $Repo"
try {
    $release = Invoke-RestMethod -Uri $releaseUri -Headers $headers
}
catch {
    throw "Cannot read the latest GitHub Release for $Repo. Make sure the repository and release are public, or set GITHUB_TOKEN when installing from a private repository."
}
$asset = Get-WindowsTuiAsset -Release $release

$destination = Join-Path $buildPath 'rhcsa-tui.exe'
Write-InstallLine "Downloading $($asset.name) from $($release.tag_name)"
$downloadUri = $asset.browser_download_url
$downloadHeaders = $headers.Clone()
if ($env:GITHUB_TOKEN -and $asset.url) {
    $downloadUri = $asset.url
    $downloadHeaders['Accept'] = 'application/octet-stream'
}
Invoke-WebRequest -Uri $downloadUri -OutFile $destination -Headers $downloadHeaders

$launcher = Join-Path $projectPath 'rhcsa-tui.cmd'
if (-not (Test-Path $launcher -PathType Leaf)) {
    @'
@echo off
setlocal
cd /d "%~dp0"
if exist ".build\rhcsa-tui.exe" (
  ".build\rhcsa-tui.exe" --project-root "%~dp0"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RHCSA.ps1" tui
)
echo.
pause
'@ | Set-Content -Path $launcher -Encoding ASCII
}

Write-InstallLine "Installed TUI to $destination"
Write-InstallLine "Run .\RHCSA.ps1 tui from PowerShell, or double-click rhcsa-tui.cmd."

if ($Launch) {
    & $destination --project-root $projectPath
}
