Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:WorkflowProgressArea = $null
$script:WorkflowProgressIndex = 0
$script:WorkflowProgressTotal = 0
$script:WorkflowProgressStartedAt = $null
$script:WorkflowProgressMessage = ''
$script:ShowWorkflowStatus = $false
$script:WorkflowProgressLastHeartbeat = $null
$script:WorkflowProgressLineActive = $false
$script:WorkflowProgressRow = $null
$script:WorkflowProgressCursorVisible = $null

function Test-WorkflowVerboseOutput {
return ($env:RHCSA_VERBOSE -match '^(1|true|yes|on)$')
}

function Test-WorkflowStatusMessageVisible {
param(
[Parameter(Mandatory = $true)]
[string]$Message
)

if (Test-WorkflowVerboseOutput) {
return $true
}

$quietPattern = @(
'^Waiting for .+ SSH readiness before provisioning \(\d+/\d+\)$',
'^Confirmed .+ SSH once; waiting for stable readiness \(\d+/\d+\)$',
'^Configuring .+ private network$',
'^Running .+ on .+$',
'^Recovered from a partial .+$',
'^Extending .+ SSH readiness wait before provisioning$',
'^Retrying .+ startup after a transient post-restore SSH readiness failure$',
'^Falling back to Vagrant .+$',
'^Restoring the clean baseline snapshots$',
'^Applying the .+ overlay for .+$',
'^Resetting .+ after RHCSA10 boot readiness stalled$',
'^Starting (server|client)$',
'^Starting .+ from the clean baseline$'
) -join '|'

return ([string]$Message -notmatch $quietPattern)
}

function Set-WorkflowProgress {
[CmdletBinding(SupportsShouldProcess)]
param(
[string]$Area,
[int]$Index,
[int]$Total
)

if (-not $PSCmdlet.ShouldProcess('workflow progress', 'Set')) {
return
}

$resetProgress = (
    [string]$script:WorkflowProgressArea -ne [string]$Area -or
    [int]$script:WorkflowProgressTotal -ne [int]$Total -or
    $Index -le 0 -or
    $null -eq $script:WorkflowProgressStartedAt
)

$script:WorkflowProgressArea = $Area
$script:WorkflowProgressIndex = $Index
$script:WorkflowProgressTotal = $Total
if ($resetProgress) {
    $script:WorkflowProgressStartedAt = Get-Date
    $script:WorkflowProgressMessage = ''
    $script:WorkflowProgressLastHeartbeat = $null
    $script:WorkflowProgressLineActive = $false
    $script:WorkflowProgressRow = $null
    $script:WorkflowProgressCursorVisible = $null
}
}

function Set-ShowWorkflowStatus {
[CmdletBinding(SupportsShouldProcess)]
param(
[bool]$Enabled
)

if (-not $PSCmdlet.ShouldProcess('workflow status output', 'Set')) {
return
}

$script:ShowWorkflowStatus = $Enabled
}

function Test-WorkflowUnicodeProgress {
if ($env:RHCSA_ASCII_PROGRESS -match '^(1|true|yes|on)$') {
return $false
}

try {
if ([Console]::OutputEncoding.CodePage -ne 65001) {
return $false
}
}
catch {
return $false
}

return $true
}

function Set-WorkflowProgressCursorHidden {
try {
if (-not [Console]::IsOutputRedirected) {
if ($null -eq $script:WorkflowProgressCursorVisible) {
$script:WorkflowProgressCursorVisible = [Console]::CursorVisible
}
[Console]::CursorVisible = $false
}
}
catch {
}
}

function Restore-WorkflowProgressCursor {
try {
if (-not [Console]::IsOutputRedirected -and $null -ne $script:WorkflowProgressCursorVisible) {
[Console]::CursorVisible = [bool]$script:WorkflowProgressCursorVisible
}
}
catch {
}
$script:WorkflowProgressCursorVisible = $null
}

function Set-WorkflowProgressCursorToRow {
try {
if ($null -eq $script:WorkflowProgressRow) {
$script:WorkflowProgressRow = [Console]::CursorTop
}

$row = [int]$script:WorkflowProgressRow
$bufferHeight = [Math]::Max([Console]::BufferHeight, 1)
if ($row -ge $bufferHeight) {
$row = $bufferHeight - 1
$script:WorkflowProgressRow = $row
}

[Console]::SetCursorPosition(0, $row)
return $true
}
catch {
return $false
}
}

function Write-WorkflowProgressBlock {
param(
[Parameter(Mandatory = $true)]
[string[]]$Lines
)

$height = @($Lines).Count
if ($height -eq 0) {
return
}

$interactive = $false
try {
$interactive = (-not [Console]::IsOutputRedirected)
}
catch {
$interactive = $false
}

if (-not $interactive) {
foreach ($line in $Lines) {
[Console]::Out.WriteLine($line)
}
return
}

try {
$bufferWidth = [Math]::Max([Console]::BufferWidth, 1)
$text = ([string]::Join(' ', @($Lines))).Trim()
if ($text.Length -gt ($bufferWidth - 1)) {
    $text = $text.Substring(0, [Math]::Max($bufferWidth - 1, 0))
}
if ($text.Length -lt ($bufferWidth - 1)) {
    $text = $text + (' ' * (($bufferWidth - 1) - $text.Length))
}
Set-WorkflowProgressCursorHidden
if (Set-WorkflowProgressCursorToRow) {
[Console]::Out.Write($text)
}
else {
[Console]::Out.Write("`r$text")
}
$script:WorkflowProgressLineActive = $true
}
catch {
foreach ($line in $Lines) {
[Console]::Out.WriteLine($line)
}
$script:WorkflowProgressLineActive = $false
}
}

function Get-WorkflowProgressLine {
param(
[string]$Status,
[int]$Current,
[int]$Total
)

if ($Total -le 0) { $Total = 1 }
if ($Current -lt 0) { $Current = 0 }
if ($Current -gt $Total) { $Current = $Total }

$percent = [int][Math]::Floor(([double]$Current / [double]$Total) * 100)
if ($percent -lt 0) { $percent = 0 }
if ($percent -gt 100) { $percent = 100 }

$barWidth = 34
$filled = [int][Math]::Floor(($barWidth * [double]$percent) / 100.0)
if ($filled -lt 0) { $filled = 0 }
if ($filled -gt $barWidth) { $filled = $barWidth }
$empty = $barWidth - $filled

if (Test-WorkflowUnicodeProgress) {
    $bar = ([string]([char]0x2588) * $filled) + ([string]([char]0x2591) * $empty)
}
else {
    $bar = ('#' * $filled) + ('-' * $empty)
}

$elapsed = '00:00:00'
if ((Test-Path variable:script:WorkflowProgressStartedAt) -and $null -ne $script:WorkflowProgressStartedAt) {
    $span = (Get-Date) - [datetime]$script:WorkflowProgressStartedAt
    $elapsed = '{0:00}:{1:00}:{2:00}' -f [Math]::Floor($span.TotalHours), $span.Minutes, $span.Seconds
}

$statusText = ([string]$Status).Trim()
if ([string]::IsNullOrWhiteSpace($statusText)) {
    $statusText = 'Working'
}

return ('[{0}] {1,3}%  {2}/{3}  Elapsed: {4}  {5}' -f $bar, $percent, $Current, $Total, $elapsed, $statusText)
}

function Write-WorkflowStatus {
param(
[Parameter(Mandatory = $true)]
[string]$Area,
[Parameter(Mandatory = $true)]
[string]$Message,
[int]$Index = -1
)

$isVerbose = $false
if (Test-Path variable:script:ShowWorkflowStatus) {
$isVerbose = [bool]$script:ShowWorkflowStatus
}
elseif (Test-WorkflowVerboseOutput) {
$isVerbose = $true
}

if (-not $isVerbose) {
return
}

if (-not (Test-WorkflowStatusMessageVisible -Message $Message)) {
return
}

$script:WorkflowProgressMessage = [string]$Message
$current = 0
$total = 0
if ((Test-Path variable:script:WorkflowProgressArea) -and
(Test-Path variable:script:WorkflowProgressTotal) -and
([string]$script:WorkflowProgressArea -eq $Area) -and
([int]$script:WorkflowProgressTotal -gt 0)) {
if (-not (Test-Path variable:script:WorkflowProgressIndex)) {
$script:WorkflowProgressIndex = 0
}

if ($Index -ge 0) {
$script:WorkflowProgressIndex = [Math]::Min([Math]::Max($Index, 0), [int]$script:WorkflowProgressTotal)
}
else {
$script:WorkflowProgressIndex = [Math]::Min(([int]$script:WorkflowProgressIndex + 1), [int]$script:WorkflowProgressTotal)
}
$current = [int]$script:WorkflowProgressIndex
$total = [int]$script:WorkflowProgressTotal
}

if ($total -le 0) {
$current = 1
$total = 1
}

$line = Get-WorkflowProgressLine -Status $Message -Current $current -Total $total
Write-WorkflowProgressBlock -Lines @($line)
$script:WorkflowProgressLastHeartbeat = Get-Date
}

function Write-WorkflowProgressHeartbeat {
param()

if (-not (Test-Path variable:script:ShowWorkflowStatus) -or -not [bool]$script:ShowWorkflowStatus) {
return
}

try {
if ([Console]::IsOutputRedirected) {
return
}
}
catch {
return
}

if ((Test-Path variable:script:WorkflowProgressTotal) -and [int]$script:WorkflowProgressTotal -le 0) {
return
}

$now = Get-Date
if ((Test-Path variable:script:WorkflowProgressLastHeartbeat) -and $null -ne $script:WorkflowProgressLastHeartbeat) {
    if (($now - [datetime]$script:WorkflowProgressLastHeartbeat).TotalMilliseconds -lt 900) {
        return
    }
}

$line = Get-WorkflowProgressLine -Status $script:WorkflowProgressMessage -Current ([int]$script:WorkflowProgressIndex) -Total ([int]$script:WorkflowProgressTotal)
Write-WorkflowProgressBlock -Lines @($line)
$script:WorkflowProgressLastHeartbeat = $now
}

function Complete-WorkflowProgress {
param(
[Parameter(Mandatory = $true)]
[string]$Area,
[string]$Message = 'Complete'
)

if (-not (Test-Path variable:script:ShowWorkflowStatus) -or -not [bool]$script:ShowWorkflowStatus) {
return
}

if ((Test-Path variable:script:WorkflowProgressArea) -and [string]$script:WorkflowProgressArea -ne [string]$Area) {
return
}

$total = 1
if ((Test-Path variable:script:WorkflowProgressTotal) -and [int]$script:WorkflowProgressTotal -gt 0) {
    $total = [int]$script:WorkflowProgressTotal
}
$script:WorkflowProgressIndex = $total
$script:WorkflowProgressMessage = [string]$Message
$line = Get-WorkflowProgressLine -Status $Message -Current $total -Total $total
Write-WorkflowProgressBlock -Lines @($line)
try {
    if (-not [Console]::IsOutputRedirected) {
        [void](Set-WorkflowProgressCursorToRow)
        [Console]::Out.WriteLine()
    }
}
catch {
    [Console]::Out.WriteLine()
}
$script:WorkflowProgressLineActive = $false
$script:WorkflowProgressRow = $null
Restore-WorkflowProgressCursor
}

function Stop-WorkflowProgress {
param(
[string]$Area = ''
)

if ((Test-Path variable:script:WorkflowProgressArea) -and
    -not [string]::IsNullOrWhiteSpace($Area) -and
    [string]$script:WorkflowProgressArea -ne [string]$Area) {
return
}

$lineWasActive = $false
if (Test-Path variable:script:WorkflowProgressLineActive) {
$lineWasActive = [bool]$script:WorkflowProgressLineActive
}

if ($lineWasActive) {
try {
if (-not [Console]::IsOutputRedirected) {
[void](Set-WorkflowProgressCursorToRow)
[Console]::Out.WriteLine()
}
}
catch {
[Console]::Out.WriteLine()
}
}

$script:WorkflowProgressArea = $null
$script:WorkflowProgressIndex = 0
$script:WorkflowProgressTotal = 0
$script:WorkflowProgressStartedAt = $null
$script:WorkflowProgressMessage = ''
$script:WorkflowProgressLastHeartbeat = $null
$script:WorkflowProgressLineActive = $false
$script:WorkflowProgressRow = $null
Restore-WorkflowProgressCursor
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

$lineWasActive = $false
if (Test-Path variable:script:WorkflowProgressLineActive) {
$lineWasActive = [bool]$script:WorkflowProgressLineActive
}
if ($lineWasActive) {
try {
if (-not [Console]::IsOutputRedirected) {
[void](Set-WorkflowProgressCursorToRow)
[Console]::Out.WriteLine()
}
}
catch {
[Console]::Out.WriteLine()
}
$script:WorkflowProgressLineActive = $false
$script:WorkflowProgressRow = $null
Restore-WorkflowProgressCursor
}

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
