Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
param(
[string]$Start = $PSScriptRoot
)

try {
$current = (Resolve-Path $Start).Path
}
catch {
$current = $Start
}

while (-not [string]::IsNullOrWhiteSpace($current)) {
if (Test-Path (Join-Path $current 'Vagrantfile')) {
return (Resolve-Path $current).Path
}
$parent = Split-Path -Parent $current
if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) {
break
}
$current = $parent
}

throw "Vagrantfile not found from '$Start' upward."
}

function Get-LabStateRoot {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path $ProjectRoot '.lab-state')
}

function Get-ProjectProfilePath {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path $ProjectRoot '.rhcsa-profile.json')
}

function ConvertTo-ProjectProfile {
param(
[AllowEmptyString()]
[string]$Profile
)

$value = ([string]$Profile).Trim().ToLowerInvariant() -replace '[-_]', ''
switch ($value) {
{ $_ -in @('', '9', 'rhel9', 'rhcsa9', 'ex2009') } { return 'rhel9' }
{ $_ -in @('10', 'rhel10', 'rhcsa10', 'ex20010') } { return 'rhel10' }
default { throw "Unsupported project profile '$Profile'. Use RHCSA9 or RHCSA10." }
}
}

function Get-ProjectTrackFromProfile {
param(
[AllowEmptyString()]
[string]$Profile
)

switch (ConvertTo-ProjectProfile -Profile $Profile) {
'rhel10' { return 'rhcsa10' }
default { return 'rhcsa9' }
}
}

function Get-ProjectProfile {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$data = Get-ProjectProfileData -ProjectRoot $ProjectRoot
if ($null -eq $data) {
return 'rhel9'
}

$profileValue = ''
if ($null -ne $data.PSObject.Properties['profile']) {
$profileValue = [string]$data.profile
}
elseif ($null -ne $data.PSObject.Properties['track']) {
$profileValue = [string]$data.track
}

return (ConvertTo-ProjectProfile -Profile $profileValue)
}

function Get-ProjectScenarioTrack {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Get-ProjectTrackFromProfile -Profile (Get-ProjectProfile -ProjectRoot $ProjectRoot))
}

function Get-ProjectProfileData {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$path = Get-ProjectProfilePath -ProjectRoot $ProjectRoot
if (-not (Test-Path -LiteralPath $path)) {
return $null
}

$raw = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
if ([string]::IsNullOrWhiteSpace($raw)) {
return $null
}

try {
return ($raw | ConvertFrom-Json -ErrorAction Stop)
}
catch {
throw "Invalid project profile file '$path'."
}
}

function Get-ProjectTimerDefault {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$data = Get-ProjectProfileData -ProjectRoot $ProjectRoot
if ($null -eq $data -or $null -eq $data.PSObject.Properties['timer_default_enabled']) {
return $false
}

return [bool]$data.timer_default_enabled
}

function Get-GeneratedRuntimeRoot {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path (Get-LabStateRoot -ProjectRoot $ProjectRoot) 'generated')
}

function Get-GeneratedLabRuntimeRoot {
param(
[Parameter(Mandatory = $true)]
[string]$ScenarioId,
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path (Get-GeneratedRuntimeRoot -ProjectRoot $ProjectRoot) $ScenarioId)
}

function Get-GeneratedLabMetadataPath {
param(
[Parameter(Mandatory = $true)]
[string]$ScenarioId,
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path (Get-GeneratedLabRuntimeRoot -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot) 'exercise.json')
}

function Get-ActiveRunPath {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path (Get-LabStateRoot -ProjectRoot $ProjectRoot) 'active-run.json')
}

function Get-BaseSnapshotStatePath {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path (Get-LabStateRoot -ProjectRoot $ProjectRoot) 'base-snapshots.json')
}

function Get-LabDiskGenerationPath {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path (Get-LabStateRoot -ProjectRoot $ProjectRoot) 'disk-generation.txt')
}

function Get-LabDisksRoot {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path $ProjectRoot '.lab-disks')
}

function Get-LabDiskGenerationToken {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$path = Get-LabDiskGenerationPath -ProjectRoot $ProjectRoot
if (-not (Test-Path -LiteralPath $path)) {
return ''
}

$content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
if ($null -eq $content) {
$content = ''
}

return $content.Trim() -replace '[^0-9A-Za-z_-]', ''
}

function Get-ClientLabDiskPath {
param(
[ValidateRange(1, 99)]
[int]$DiskNumber,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$generation = Get-LabDiskGenerationToken -ProjectRoot $ProjectRoot
$suffix = if ([string]::IsNullOrWhiteSpace($generation)) { '' } else { "-$generation" }
return (Join-Path (Get-LabDisksRoot -ProjectRoot $ProjectRoot) ("client-disk{0}{1}.vdi" -f $DiskNumber, $suffix))
}

function Set-LabDiskGeneration {
[CmdletBinding(SupportsShouldProcess)]
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
$generation = [System.Guid]::NewGuid().ToString('N')
if ($PSCmdlet.ShouldProcess((Get-LabDiskGenerationPath -ProjectRoot $ProjectRoot), 'Write lab disk generation token')) {
Set-Utf8NoBomFile -Path (Get-LabDiskGenerationPath -ProjectRoot $ProjectRoot) -Content $generation
}
return $generation
}

function Set-Utf8NoBomFile {
[CmdletBinding(SupportsShouldProcess)]
param(
[Parameter(Mandatory = $true)]
[string]$Path,
[Parameter(Mandatory = $true)]
[AllowEmptyString()]
[string]$Content
)

$directory = Split-Path -Parent $Path
if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path $directory)) {
New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

if ($PSCmdlet.ShouldProcess($Path, 'Write UTF-8 text without BOM')) {
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}
}

function Set-ProjectProfile {
[CmdletBinding(SupportsShouldProcess)]
param(
[Parameter(Mandatory = $true)]
[string]$Profile,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$normalizedProfile = ConvertTo-ProjectProfile -Profile $Profile
$track = Get-ProjectTrackFromProfile -Profile $normalizedProfile
$path = Get-ProjectProfilePath -ProjectRoot $ProjectRoot
$timerDefault = Get-ProjectTimerDefault -ProjectRoot $ProjectRoot
$content = ([ordered]@{
profile = $normalizedProfile
track = $track
timer_default_enabled = $timerDefault
} | ConvertTo-Json)

if ($PSCmdlet.ShouldProcess($path, 'Write project profile')) {
Set-Utf8NoBomFile -Path $path -Content $content
}

return [PSCustomObject]@{
Profile = $normalizedProfile
Track = $track
Path = $path
TimerDefaultEnabled = $timerDefault
}
}

function Set-ProjectTimerDefault {
[CmdletBinding(SupportsShouldProcess)]
param(
[Parameter(Mandatory = $true)]
[bool]$Enabled,
[string]$ProjectRoot = (Get-ProjectRoot)
)

$data = Get-ProjectProfileData -ProjectRoot $ProjectRoot
$profile = 'rhel9'
if ($null -ne $data) {
if ($null -ne $data.PSObject.Properties['profile']) {
$profile = [string]$data.profile
}
elseif ($null -ne $data.PSObject.Properties['track']) {
$profile = [string]$data.track
}
}

$normalizedProfile = ConvertTo-ProjectProfile -Profile $profile
$track = Get-ProjectTrackFromProfile -Profile $normalizedProfile
$path = Get-ProjectProfilePath -ProjectRoot $ProjectRoot
$content = ([ordered]@{
profile = $normalizedProfile
track = $track
timer_default_enabled = [bool]$Enabled
} | ConvertTo-Json)

if ($PSCmdlet.ShouldProcess($path, 'Write project timer default')) {
Set-Utf8NoBomFile -Path $path -Content $content
}

return [PSCustomObject]@{
Enabled = [bool]$Enabled
Profile = $normalizedProfile
Track = $track
Path = $path
}
}

function Initialize-LabStateLayout {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

$stateRoot = Get-LabStateRoot -ProjectRoot $ProjectRoot
$runsRoot = Join-Path $stateRoot 'runs'
$generatedRoot = Join-Path $stateRoot 'generated'

foreach ($path in @($stateRoot, $runsRoot, $generatedRoot)) {
if (-not (Test-Path $path)) {
New-Item -ItemType Directory -Path $path | Out-Null
}
}

return $stateRoot
}

Export-ModuleMember -Function *
