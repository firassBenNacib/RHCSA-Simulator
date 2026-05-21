Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../FileHelpers/FileHelpers.psd1')
Import-Module (Join-Path $PSScriptRoot '../LabState/LabState.psd1')
Import-Module (Join-Path $PSScriptRoot '../Scenarios/Scenarios.psd1')

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

function Set-VagrantHostToolPath {
if ([string]::IsNullOrWhiteSpace($env:WINDIR)) {
return
}

$system32 = Join-Path $env:WINDIR 'System32'
if (-not (Test-Path $system32 -PathType Container)) {
return
}

$vagrantBin = Join-Path $env:ProgramFiles 'Vagrant\bin'
$currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Process)
if ([string]::IsNullOrWhiteSpace($currentPath)) {
$currentPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process)
}
if ([string]::IsNullOrWhiteSpace($currentPath)) {
$currentPath = [string]$env:Path
}

$pathParts = @()
foreach ($pathPart in @($system32, $vagrantBin) + @(([string]$currentPath -split ';'))) {
if ([string]::IsNullOrWhiteSpace($pathPart)) {
continue
}

if ($pathParts -notcontains $pathPart) {
$pathParts += $pathPart
}
}

$newPath = ($pathParts -join ';')
if ($newPath -ne $currentPath) {
[System.Environment]::SetEnvironmentVariable('Path', $newPath, [System.EnvironmentVariableTarget]::Process)
[System.Environment]::SetEnvironmentVariable('PATH', $newPath, [System.EnvironmentVariableTarget]::Process)
$env:Path = $newPath
}

$pathExt = [System.Environment]::GetEnvironmentVariable('PATHEXT', [System.EnvironmentVariableTarget]::Process)
if ([string]::IsNullOrWhiteSpace($pathExt) -or $pathExt -notmatch '(?i)(^|;)\.EXE($|;)') {
$pathExt = '.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC;.CPL'
[System.Environment]::SetEnvironmentVariable('PATHEXT', $pathExt, [System.EnvironmentVariableTarget]::Process)
$env:PATHEXT = $pathExt
}
}

function Get-VagrantCommandSpec {
param()

Set-VagrantHostToolPath
$vagrantPath = Get-VagrantPath
if (-not [string]::IsNullOrWhiteSpace($env:ComSpec) -and (Test-Path $env:ComSpec -PathType Leaf)) {
return [PSCustomObject]@{
FilePath = $env:ComSpec
PrefixArgumentList = @('/d', '/s', '/c', 'vagrant')
}
}

return [PSCustomObject]@{
FilePath = $vagrantPath
PrefixArgumentList = @()
}
}

function Get-ProjectVagrantBoxName {
param(
[string]$ProjectRoot = (Get-ProjectRoot),
[AllowEmptyString()]
[Alias('Profile')]
[string]$ProjectProfile = ''
)

if ([string]::IsNullOrWhiteSpace($ProjectProfile)) {
$ProjectProfile = Get-ProjectProfile -ProjectRoot $ProjectRoot
}

$override = [string]$env:RHCSA_BOX
if (-not [string]::IsNullOrWhiteSpace($override)) {
return $override.Trim()
}

switch (ConvertTo-ProjectProfile -Profile $ProjectProfile) {
'rhel10' { return 'boxomatic/almalinux-10' }
default { return 'generic/rocky9' }
}
}

function Get-ProjectVagrantBoxUrl {
param(
[string]$ProjectRoot = (Get-ProjectRoot),
[AllowEmptyString()]
[Alias('Profile')]
[string]$ProjectProfile = ''
)

if ([string]::IsNullOrWhiteSpace($ProjectProfile)) {
$ProjectProfile = Get-ProjectProfile -ProjectRoot $ProjectRoot
}

$override = [string]$env:RHCSA_BOX_URL
if (-not [string]::IsNullOrWhiteSpace($override)) {
return $override.Trim()
}

switch (ConvertTo-ProjectProfile -Profile $ProjectProfile) {
default { return '' }
}
}

function Test-CurlExecutableAvailable {
if ($null -ne (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
return $true
}

$windowsCurl = Join-Path $env:WINDIR 'System32\curl.exe'
return (Test-Path $windowsCurl -PathType Leaf)
}

function Test-VagrantArchiveExtractorAvailable {
if ($null -ne (Get-Command bsdtar.exe -ErrorAction SilentlyContinue)) {
return $true
}

if ($null -ne (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
return $true
}

$windowsTar = Join-Path $env:WINDIR 'System32\tar.exe'
return (Test-Path $windowsTar -PathType Leaf)
}

function Test-VagrantBoxInstalled {
param(
[Parameter(Mandatory = $true)]
[string]$BoxName,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$vagrantCommand = Get-VagrantCommandSpec
$result = Invoke-ExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('box', 'list')) -TimeoutSeconds 180
if ($result.ExitCode -ne 0) {
return $false
}

$pattern = '^{0}\s+\(' -f [regex]::Escape($BoxName)
foreach ($line in @($result.StdOut)) {
if ([string]$line -match $pattern) {
return $true
}
}

return $false
}

function Assert-ProjectVagrantBoxReady {
param(
[string]$ProjectRoot = (Get-ProjectRoot),
[AllowEmptyString()]
[Alias('Profile')]
[string]$ProjectProfile = ''
)

if ([string]::IsNullOrWhiteSpace($ProjectProfile)) {
$ProjectProfile = Get-ProjectProfile -ProjectRoot $ProjectRoot
}

$boxName = Get-ProjectVagrantBoxName -ProjectRoot $ProjectRoot -Profile $ProjectProfile
if (Test-VagrantBoxInstalled -BoxName $boxName -ProjectRoot $ProjectRoot) {
return
}

$boxUrl = Get-ProjectVagrantBoxUrl -ProjectRoot $ProjectRoot -Profile $ProjectProfile

$missing = @()
if (-not (Test-CurlExecutableAvailable)) {
$missing += 'curl.exe'
}
if (-not (Test-VagrantArchiveExtractorAvailable)) {
$missing += 'tar.exe or bsdtar.exe'
}

if ($missing.Count -eq 0) {
return
}

$missingText = if ($missing.Count -gt 0) {
" Missing host prerequisites: $($missing -join ', ')."
}
else {
''
}

$installCommand = if ([string]::IsNullOrWhiteSpace($boxUrl)) {
"vagrant box add $boxName --provider virtualbox"
}
else {
"vagrant box add $boxName $boxUrl --provider virtualbox"
}

throw "The configured Vagrant box '$boxName' is not installed for this project profile.$missingText Install it first with: $installCommand"
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
[AllowEmptyString()]
[string]$Track = ''
)

$goPath = Get-GoExecutablePath
$binaryPath = Get-RhcsaTuiBinaryPath -ProjectRoot $ProjectRoot
$buildRoot = Split-Path -Parent $binaryPath
$launchBinaryPath = $binaryPath

if ([string]::IsNullOrWhiteSpace($Track)) {
    $Track = Get-ProjectScenarioTrack -ProjectRoot $ProjectRoot
}

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
