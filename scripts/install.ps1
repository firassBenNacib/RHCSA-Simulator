#Requires -Version 5

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Version = "latest",

    [Parameter()]
    [string]$InstallPath = "$env:LOCALAPPDATA\Programs\rhcsa-tui",

    [Parameter()]
    [switch]$AddToPath
)

$ErrorActionPreference = "Stop"
$BinaryName = "rhcsa-tui"
$Repo = "bennacib/rhcsa_exam_vms"
$Owner = "bennacib"

function Get-LatestVersion {
    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
    return $releases.tag_name
}

function Get-OsArch {
    $os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "darwin" } elseif ($IsLinux) { "linux" } else { "windows" }
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
    return @{ Os = $os; Arch = $arch }
}

function Install-RhcsaTui {
    param(
        [string]$Version,
        [string]$InstallPath
    )

    if ($Version -eq "latest") {
        $Version = Get-LatestVersion
    }

    $info = Get-OsArch
    $os = $info.Os
    $arch = $info.Arch
    $filename = "$BinaryName`_$os`_$arch.zip"
    $downloadUrl = "https://github.com/$Repo/releases/download/$Version/$filename"

    Write-Host "Installing $BinaryName $Version for $os/$arch..." -ForegroundColor Cyan

    $tempFile = [System.IO.Path]::GetTempFileName() + ".zip"
    try {
        Write-Host "Downloading $downloadUrl..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing

        Write-Host "Extracting..." -ForegroundColor Yellow
        Expand-Archive -Path $tempFile -DestinationPath $InstallPath -Force

        $exePath = Join-Path $InstallPath "$BinaryName.exe"
        if (-not (Test-Path $exePath)) {
            $exePath = Join-Path $InstallPath $BinaryName
        }

        if (Test-Path $exePath) {
            Write-Host ""
            Write-Host "Installed to: $exePath" -ForegroundColor Green
            Write-Host ""

            if ($AddToPath -or $env:RHCSA_TUI_ADD_TO_PATH) {
                $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
                if ($userPath -notlike "*$InstallPath*") {
                    [System.Environment]::SetEnvironmentVariable(
                        "Path",
                        "$userPath;$InstallPath",
                        "User"
                    )
                    $env:Path = "$env:Path;$InstallPath"
                    Write-Host "Added to PATH" -ForegroundColor Green
                }
            } else {
                Write-Host "Add to PATH manually or run with -AddToPath flag" -ForegroundColor Yellow
            }
        } else {
            throw "Installation failed: executable not found"
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

function Show-Help {
    Write-Host @"
Usage: install.ps1 [version] [options]

Options:
  -Version <version>     Version to install (default: latest)
  -InstallPath <path>    Installation directory (default: $env:LOCALAPPDATA\Programs\rhcsa-tui)
  -AddToPath             Add installation directory to PATH
  -Help                  Show this help

Examples:
  .\install.ps1                    Install latest version
  .\install.ps1 -Version v1.0.0    Install specific version
  .\install.ps1 -AddToPath        Install and add to PATH

"@
}

if ($Version -eq "-Help" -or $Version -eq "-?") {
    Show-Help
    exit 0
}

try {
    Install-RhcsaTui -Version $Version -InstallPath $InstallPath
} catch {
    Write-Error "Installation failed: $_"
    exit 1
}
