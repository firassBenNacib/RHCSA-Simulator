Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:WorkflowProgressArea = $null
$script:WorkflowProgressIndex = 0
$script:WorkflowProgressTotal = 0
$script:ShowWorkflowStatus = $false

function Set-WorkflowProgress {
param(
[string]$Area,
[int]$Index,
[int]$Total
)

$script:WorkflowProgressArea = $Area
$script:WorkflowProgressIndex = $Index
$script:WorkflowProgressTotal = $Total
}

function Set-ShowWorkflowStatus {
param(
[bool]$Enabled
)

$script:ShowWorkflowStatus = $Enabled
}

function Write-WorkflowStatus {
param(
[Parameter(Mandatory = $true)]
[string]$Area,
[Parameter(Mandatory = $true)]
[string]$Message
)

$isVerbose = $false
if (Test-Path variable:script:ShowWorkflowStatus) {
$isVerbose = [bool]$script:ShowWorkflowStatus
}
elseif ($env:RHCSA_VERBOSE -match '^(1|true|yes|on)$') {
$isVerbose = $true
}

if (-not $isVerbose) {
return
}

$prefix = 'INFO'
if (Get-Command Get-UiStyleCode -ErrorAction SilentlyContinue) {
$prefix = '{0}{1}{2}' -f (Get-UiStyleCode -StyleName 'Accent'), 'INFO', (Get-UiStyleCode -StyleName 'Reset')
}

$progressPrefix = ''
if ((Test-Path variable:script:WorkflowProgressArea) -and
(Test-Path variable:script:WorkflowProgressTotal) -and
([string]$script:WorkflowProgressArea -eq $Area) -and
([int]$script:WorkflowProgressTotal -gt 0)) {
if (-not (Test-Path variable:script:WorkflowProgressIndex)) {
$script:WorkflowProgressIndex = 0
}

$script:WorkflowProgressIndex = [Math]::Min(([int]$script:WorkflowProgressIndex + 1), [int]$script:WorkflowProgressTotal)
$current = [int]$script:WorkflowProgressIndex
$total = [int]$script:WorkflowProgressTotal
$progressPrefix = '[{0}/{1}] ' -f $current, $total
}

[Console]::Out.WriteLine(('{0} {1}{2}' -f $prefix, $progressPrefix, $Message))
}

function Test-ProgressOnlyOutputLine {
param(
[Parameter(Mandatory = $true)]
[string]$Line
)

$trimmed = $Line.Trim()
return ($trimmed -match '^\d+%(?:\.\.\.\d+%)*$')
}

function Write-FailureTranscript {
param(
[string[]]$StdOut = @(),
[string[]]$StdErr = @()
)

$emitted = $false
foreach ($line in @($StdOut) + @($StdErr)) {
$text = [string]$line
if ([string]::IsNullOrWhiteSpace($text)) {
continue
}

if (Test-ProgressOnlyOutputLine -Line $text) {
continue
}

[Console]::Out.WriteLine($text)
$emitted = $true
}

return $emitted
}

Export-ModuleMember -Function *
