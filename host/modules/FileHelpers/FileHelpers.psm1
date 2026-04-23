Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
param(
[string]$Start = $PSScriptRoot
)

if (Test-Path (Join-Path $Start 'Vagrantfile')) {
return (Resolve-Path $Start).Path
}

$parent = Split-Path -Parent $Start
if ($parent -and (Test-Path (Join-Path $parent 'Vagrantfile'))) {
return (Resolve-Path $parent).Path
}

throw "Vagrantfile not found in '$Start' or its parent."
}

function Get-LabStateRoot {
param(
[string]$ProjectRoot = (Get-ProjectRoot)
)

return (Join-Path $ProjectRoot '.lab-state')
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
