Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1') -Force
Import-Module (Join-Path $PSScriptRoot '../LabState/LabState.psd1') -Force
Import-Module (Join-Path $PSScriptRoot '../Scenarios/Scenarios.psd1') -Force

function Get-OptionalVBoxManagePath {
$command = Get-Command VBoxManage -ErrorAction SilentlyContinue
if ($null -ne $command) {
return $command.Source
}

$default64 = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
if (Test-Path $default64) {
return $default64
}

$programFiles86 = ${env:ProgramFiles(x86)}
if ($programFiles86) {
$default32 = Join-Path $programFiles86 'Oracle\VirtualBox\VBoxManage.exe'
if (Test-Path $default32) {
return $default32
}
}

return $null
}

function Get-OptionalVagrantPath {
$command = Get-Command vagrant -ErrorAction SilentlyContinue
if ($null -ne $command) {
return $command.Source
}

$default64 = Join-Path $env:ProgramFiles 'Vagrant\bin\vagrant.exe'
if (Test-Path $default64) {
return $default64
}

$programFiles86 = ${env:ProgramFiles(x86)}
if ($programFiles86) {
$default32 = Join-Path $programFiles86 'Vagrant\bin\vagrant.exe'
if (Test-Path $default32) {
return $default32
}
}

return $null
}

function Get-VagrantPath {
$path = Get-OptionalVagrantPath
if (-not $path) {
throw 'Vagrant not found. Install Vagrant or add it to PATH.'
}

return $path
}

function Get-VBoxManagePath {
$path = Get-OptionalVBoxManagePath
if (-not $path) {
throw 'VBoxManage not found. Install VirtualBox or add VBoxManage to PATH.'
}

return $path
}

function Get-GoExecutablePath {
$command = Get-Command go -ErrorAction SilentlyContinue
if ($null -ne $command) {
return $command.Source
}

$default64 = Join-Path $env:ProgramFiles 'Go\bin\go.exe'
if (Test-Path $default64) {
return $default64
}

throw 'Go not found. Install Go to use the RHCSA TUI.'
}

function Get-RhcsaTuiBinaryPath {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$buildRoot = Join-Path $ProjectRoot '.build'
$isWindowsHost = ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)
$binaryName = if ($isWindowsHost) { 'rhcsa-tui.exe' } else { 'rhcsa-tui' }
return (Join-Path $buildRoot $binaryName)
}

function Get-RhcsaTuiSourceFile {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$paths = @()
foreach ($sourceRoot in @(
(Join-Path $ProjectRoot 'cmd/rhcsa-tui'),
(Join-Path $ProjectRoot 'internal')
)) {
$goFiles = Get-ChildItem -Path $sourceRoot -Filter '*.go' -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName
if ($null -ne $goFiles) {
$paths += $goFiles.FullName
}
}

foreach ($path in @(
(Join-Path $ProjectRoot 'go.mod'),
(Join-Path $ProjectRoot 'go.sum')
)) {
if (Test-Path $path -PathType Leaf) {
$paths += $path
}
}

return $paths
}

function Test-RhcsaTuiBinaryIsStale {
param(
[string]$ProjectRoot = (Get-ProjectRoot),
[string]$BinaryPath = (Get-RhcsaTuiBinaryPath -ProjectRoot $ProjectRoot)
)

if (-not (Test-Path $BinaryPath -PathType Leaf)) {
return $true
}

$binaryTime = (Get-Item -Path $BinaryPath).LastWriteTimeUtc
foreach ($sourcePath in Get-RhcsaTuiSourceFile -ProjectRoot $ProjectRoot) {
try {
if ((Get-Item -Path $sourcePath).LastWriteTimeUtc -gt $binaryTime) {
return $true
}
}
catch {
continue
}
}

return $false
}

function Open-RhcsaTui {
param(
[string]$ProjectRoot = (Get-ProjectRoot),
[ValidateSet('RHCSA9', 'RHCSA10', 'All', 'rhcsa9', 'rhcsa10', 'all')]
[string]$Track = 'RHCSA9'
)

$goPath = Get-GoExecutablePath
$binaryPath = Get-RhcsaTuiBinaryPath -ProjectRoot $ProjectRoot
$buildRoot = Split-Path -Parent $binaryPath
$launchBinaryPath = $binaryPath

Push-Location $ProjectRoot
try {
if (-not (Test-Path $buildRoot)) {
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
}

$isWindowsHost = ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)
if ($isWindowsHost) {
$staleFiles = Get-ChildItem -Path $buildRoot -Filter 'rhcsa-tui-*.exe' -ErrorAction SilentlyContinue
if ($null -ne $staleFiles) {
foreach ($file in $staleFiles) {
try {
Remove-Item -Path $file.FullName -Force -ErrorAction Stop
}
catch {
Write-Verbose "Skipping removal of stale TUI launcher '$($file.FullName)' because it is currently locked."
}
}
}

$launchBinaryPath = Join-Path $buildRoot ("rhcsa-tui-{0}.exe" -f ([guid]::NewGuid().ToString('N')))
}

if (Test-RhcsaTuiBinaryIsStale -ProjectRoot $ProjectRoot -BinaryPath $binaryPath) {
Invoke-ExternalCommand `
-FilePath $goPath `
-ArgumentList @('build', '-o', $binaryPath, './cmd/rhcsa-tui') `
-FailureMessage 'Failed to build the RHCSA TUI.' `
-SuppressOutput
}

if ($isWindowsHost) {
Copy-Item -Path $binaryPath -Destination $launchBinaryPath -Force
}

Invoke-InteractiveExternalCommand `
-FilePath $launchBinaryPath `
-ArgumentList @('--project-root', $ProjectRoot, '--track', (ConvertTo-ScenarioTrack -Track $Track)) `
-FailureMessage 'Failed to open the RHCSA TUI.'
}
finally {
Pop-Location
}
}

Export-ModuleMember -Function *
