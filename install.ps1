[CmdletBinding()]
param(
    [string]$Repo = 'firassBenNacib/RHCSA-Simulator',
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'

function Write-InstallLine {
    param([string]$Message)
    Write-Information "[RHCSA] $Message" -InformationAction Continue
}

function Get-WindowsTuiAsset {
    param([object]$Release)

    $rawAsset = $Release.assets |
        Where-Object { $_.name -match '^rhcsa-tui-windows-amd64\.exe$' } |
        Select-Object -First 1

    if ($rawAsset) {
        return [pscustomobject]@{
            Asset = $rawAsset
            Kind = 'exe'
        }
    }

    $zipAsset = $Release.assets |
        Where-Object { $_.name -match '^rhcsa-tui_.*_windows_amd64\.zip$' } |
        Select-Object -First 1

    if ($zipAsset) {
        return [pscustomobject]@{
            Asset = $zipAsset
            Kind = 'zip'
        }
    }

    throw "Release '$($Release.tag_name)' does not include a Windows AMD64 TUI asset."
}

function Save-ReleaseAsset {
    param(
        [object]$Asset,
        [string]$Destination,
        [hashtable]$Headers
    )

    $downloadUri = $Asset.browser_download_url
    $downloadHeaders = $Headers.Clone()
    if ($env:GITHUB_TOKEN -and $Asset.url) {
        $downloadUri = $Asset.url
        $downloadHeaders['Accept'] = 'application/octet-stream'
    }
    Invoke-WebRequest -Uri $downloadUri -OutFile $Destination -Headers $downloadHeaders
}

function Get-ReleaseChecksumAsset {
    param([object]$Release)

    $checksumAsset = $Release.assets |
        Where-Object { $_.name -match '^(checksums\.txt|SHA256SUMS|sha256sums\.txt)$' } |
        Select-Object -First 1

    if (-not $checksumAsset) {
        throw "Release '$($Release.tag_name)' does not include a checksums.txt asset."
    }

    return $checksumAsset
}

function Get-ExpectedSha256 {
    param(
        [string]$ChecksumText,
        [string]$AssetName
    )

    foreach ($line in ($ChecksumText -split "`r?`n")) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }

        $parts = $trimmed -split '\s+'
        if ($parts.Count -lt 2 -or $parts[0] -notmatch '^[a-fA-F0-9]{64}$') {
            continue
        }

        $name = [System.IO.Path]::GetFileName($parts[-1].TrimStart('*'))
        if ($name -eq $AssetName) {
            return $parts[0].ToLowerInvariant()
        }
    }

    throw "Release checksums do not include '$AssetName'."
}

function Assert-ReleaseAssetChecksum {
    param(
        [object]$Release,
        [object]$Asset,
        [string]$FilePath,
        [string]$TempRoot,
        [hashtable]$Headers
    )

    $checksumAsset = Get-ReleaseChecksumAsset -Release $Release
    $checksumPath = Join-Path $TempRoot $checksumAsset.name
    Save-ReleaseAsset -Asset $checksumAsset -Destination $checksumPath -Headers $Headers
    $expected = Get-ExpectedSha256 -ChecksumText (Get-Content -Path $checksumPath -Raw) -AssetName $Asset.name
    $actual = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {
        throw "Checksum verification failed for '$($Asset.name)'. Expected $expected but got $actual."
    }

    Write-InstallLine "Verified SHA256 checksum for $($Asset.name)"
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
$assetInfo = Get-WindowsTuiAsset -Release $release
$asset = $assetInfo.Asset

$destination = Join-Path $buildPath 'rhcsa-tui.exe'
Write-InstallLine "Downloading $($asset.name) from $($release.tag_name)"

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("rhcsa-tui-" + [System.Guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $downloadPath = Join-Path $tempRoot $asset.name
    Save-ReleaseAsset -Asset $asset -Destination $downloadPath -Headers $headers
    Assert-ReleaseAssetChecksum -Release $release -Asset $asset -FilePath $downloadPath -TempRoot $tempRoot -Headers $headers

    if ($assetInfo.Kind -eq 'zip') {
        Expand-Archive -Path $downloadPath -DestinationPath $tempRoot -Force
        $binary = Get-ChildItem -Path $tempRoot -Recurse -Filter 'rhcsa-tui.exe' | Select-Object -First 1
        if (-not $binary) {
            throw "The release archive '$($asset.name)' did not contain rhcsa-tui.exe."
        }
        Copy-Item -Path $binary.FullName -Destination $destination -Force
    }
    else {
        Copy-Item -Path $downloadPath -Destination $destination -Force
    }
}
finally {
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

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
