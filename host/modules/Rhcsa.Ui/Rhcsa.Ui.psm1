Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../Scenarios/Scenarios.psd1')

function Test-UiColorSupport {
if ($env:NO_COLOR) {
return $false
}

return $true
}

function Get-UiStyleCode {
param(
[string]$StyleName
)

if (-not (Test-UiColorSupport)) {
return ''
}

$escape = [char]27
switch ($StyleName) {
'Header' { return "$escape[1;38;5;196m" }
'Accent' { return "$escape[1;38;5;203m" }
'Brand' { return "$escape[1;38;5;196m" }
'BrandShadow' { return "$escape[38;5;88m" }
'Success' { return "$escape[1;38;5;42m" }
'Warning' { return "$escape[1;38;5;214m" }
'Muted' { return "$escape[38;5;245m" }
'Command' { return "$escape[1;38;5;220m" }
'Exam' { return "$escape[1;38;5;203m" }
'Lab' { return "$escape[1;38;5;167m" }
'Info' { return "$escape[1;38;5;117m" }
'Reset' { return "$escape[0m" }
default { return '' }
}
}

function Format-StyledText {
param(
[string]$Text,
[string]$StyleName
)

$prefix = Get-UiStyleCode -StyleName $StyleName
if ([string]::IsNullOrEmpty($prefix)) {
return $Text
}

return '{0}{1}{2}' -f $prefix, $Text, (Get-UiStyleCode -StyleName 'Reset')
}

function Get-UiHeading {
param(
[string]$Text,
[string]$StyleName = 'Header'
)

return Format-StyledText -Text $Text -StyleName $StyleName
}

function Get-UiPlainText {
param(
[string]$Text
)

return ([string]$Text) -replace '\x1b\[[0-9;]*m', ''
}

function Get-UiBoxChar {
param(
[string]$Name
)

$hasUnicode = -not ($env:RHCSA_ASCII_UI -match '^(1|true|yes|on)$')
try {
if ($hasUnicode -and [Console]::OutputEncoding.CodePage -ne 65001) {
$hasUnicode = $false
}
}
catch {
$hasUnicode = $false
}

if (-not $hasUnicode) {
switch ($Name) {
'TopLeft' { return '+' }
'TopRight' { return '+' }
'BottomLeft' { return '+' }
'BottomRight' { return '+' }
'Horizontal' { return '-' }
'Vertical' { return '|' }
'TeeLeft' { return '+' }
'TeeRight' { return '+' }
'Bullet' { return '*' }
'Dot' { return '.' }
default { return ' ' }
}
}

switch ($Name) {
'TopLeft' { return [string][char]0x256D }
'TopRight' { return [string][char]0x256E }
'BottomLeft' { return [string][char]0x2570 }
'BottomRight' { return [string][char]0x256F }
'Horizontal' { return [string][char]0x2500 }
'Vertical' { return [string][char]0x2502 }
'TeeLeft' { return [string][char]0x251C }
'TeeRight' { return [string][char]0x2524 }
'Bullet' { return [string][char]0x25CF }
'Dot' { return [string][char]0x2500 }
default { return ' ' }
}
}

function Format-UiPanel {
param(
[string]$Title,
[string]$TitleStyle = 'Header',
[string[]]$ContentLines = @(),
[int]$MinWidth = 40,
[int]$Width = 0
)

$contentWidth = if ($Width -gt 0) { $Width } else { $MinWidth }
foreach ($line in @($ContentLines)) {
$plain = Get-UiPlainText -Text $line
if ($Width -le 0 -and $plain.Length + 3 -gt $contentWidth) {
$contentWidth = $plain.Length + 3
}
}
$titlePlain = Get-UiPlainText -Text $Title
if ($Width -le 0 -and $titlePlain.Length + 5 -gt $contentWidth) {
$contentWidth = $titlePlain.Length + 5
}

$tl = Get-UiBoxChar 'TopLeft'
$tr = Get-UiBoxChar 'TopRight'
$bl = Get-UiBoxChar 'BottomLeft'
$br = Get-UiBoxChar 'BottomRight'
$hz = Get-UiBoxChar 'Horizontal'
$vt = Get-UiBoxChar 'Vertical'

$innerWidth = $contentWidth - 2
$styledTitle = Format-StyledText -Text (" {0} " -f $Title) -StyleName $TitleStyle
$titleBar = '{0}{1}{2}{3}{4}' -f `
(Format-StyledText -Text $tl -StyleName 'Muted'),
(Format-StyledText -Text ($hz * 1) -StyleName 'Muted'),
$styledTitle,
(Format-StyledText -Text ($hz * [Math]::Max(0, $innerWidth - $titlePlain.Length - 3)) -StyleName 'Muted'),
(Format-StyledText -Text $tr -StyleName 'Muted')

$lines = @($titleBar)
foreach ($content in @($ContentLines)) {
$plainContent = Get-UiPlainText -Text $content
$pad = [Math]::Max(0, $innerWidth - $plainContent.Length - 1)
$lines += '{0} {1}{2}{3}' -f `
(Format-StyledText -Text $vt -StyleName 'Muted'),
$content,
(' ' * $pad),
(Format-StyledText -Text $vt -StyleName 'Muted')
}

$bottomBar = '{0}{1}{2}' -f `
(Format-StyledText -Text $bl -StyleName 'Muted'),
(Format-StyledText -Text ($hz * $innerWidth) -StyleName 'Muted'),
(Format-StyledText -Text $br -StyleName 'Muted')
$lines += $bottomBar

return $lines
}

function Get-ScenarioCatalogPanelWidth {
param(
[object[]]$ScenarioList = @(),
[int]$Minimum = 48
)

if (@($ScenarioList).Count -eq 0) {
return $Minimum
}

$rows = foreach ($scenario in @($ScenarioList | Sort-Object Id)) {
[PSCustomObject]@{
Id = [string]$scenario.Id
Minutes = ('{0}m' -f $scenario.TimeLimitMinutes)
Title = [string]$scenario.Title
}
}

$idWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Id }) -Minimum 2
$minutesWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Minutes }) -Minimum 4
$titleWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Title }) -Minimum 5
$tableWidth = $idWidth + 2 + $minutesWidth + 2 + $titleWidth
return [Math]::Max($Minimum, $tableWidth + 3)
}

function Format-UiKeyValue {
param(
[string]$Key,
[string]$Value,
[int]$KeyWidth = 10
)

$paddedKey = $Key.PadRight($KeyWidth)
return '{0}  {1}' -f (Format-StyledText -Text $paddedKey -StyleName 'Muted'), $Value
}

function Format-UiCommandLine {
param(
[string]$CommandText
)

return ' {0} {1}' -f (Format-StyledText -Text '>' -StyleName 'Accent'), (Format-StyledText -Text $CommandText -StyleName 'Command')
}

function Format-UiLabelValue {
param(
[string]$Label,
[string]$Value
)

return ' {0} {1}' -f (Format-StyledText -Text ("{0}:" -f $Label) -StyleName 'Accent'), $Value
}

function Get-MaxCellWidth {
param(
[AllowNull()]
[string[]]$Value = @(),
[int]$Minimum = 0
)

$maxWidth = $Minimum
foreach ($item in @($Value)) {
$itemText = [string]$item
if ($itemText.Length -gt $maxWidth) {
$maxWidth = $itemText.Length
}
}

return $maxWidth
}

function Format-PaddedCell {
param(
[string]$Text,
[int]$Width,
[string]$StyleName = ''
)

$paddedText = ([string]$Text).PadRight($Width)
if ([string]::IsNullOrWhiteSpace($StyleName)) {
return $paddedText
}

return Format-StyledText -Text $paddedText -StyleName $StyleName
}

function Format-ScenarioCatalogTable {
param(
[Parameter(Mandatory = $true)]
[string]$SectionTitle,
[Parameter(Mandatory = $true)]
[string]$SectionStyleName,
[object[]]$ScenarioList = @(),
[int]$PanelWidth = 0
)

if (@($ScenarioList).Count -eq 0) {
return @()
}

$rows = foreach ($scenario in @($ScenarioList | Sort-Object Id)) {
[PSCustomObject]@{
Id = [string]$scenario.Id
Minutes = ('{0}m' -f $scenario.TimeLimitMinutes)
Title = [string]$scenario.Title
}
}

$idWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Id }) -Minimum 2
$minutesWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Minutes }) -Minimum 4
$titleWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Title }) -Minimum 5

$headerLine = '{0}  {1}  {2}' -f `
(Format-PaddedCell -Text 'ID' -Width $idWidth -StyleName 'Accent'),
(Format-PaddedCell -Text 'TIME' -Width $minutesWidth -StyleName 'Accent'),
(Format-PaddedCell -Text 'TITLE' -Width $titleWidth -StyleName 'Accent')

$separatorLine = Format-StyledText -Text ('{0}  {1}  {2}' -f `
('-' * $idWidth), ('-' * $minutesWidth), ('-' * $titleWidth)) -StyleName 'Muted'

$contentLines = @($headerLine, $separatorLine)

foreach ($row in $rows) {
$contentLines += ('{0}  {1}  {2}' -f `
(Format-PaddedCell -Text $row.Id -Width $idWidth -StyleName 'Accent'),
(Format-PaddedCell -Text $row.Minutes -Width $minutesWidth -StyleName 'Muted'),
(Format-PaddedCell -Text $row.Title -Width $titleWidth))
}

if ($PanelWidth -gt 0) {
return @(Format-UiPanel -Title $SectionTitle -TitleStyle $SectionStyleName -ContentLines $contentLines -MinWidth $PanelWidth)
}

return @(Format-UiPanel -Title $SectionTitle -TitleStyle $SectionStyleName -ContentLines $contentLines)
}

function Format-ScenarioCatalogOutput {
param(
[object[]]$ScenarioCatalog,
[ValidateSet('all', 'labs', 'exams')]
[string]$Filter = 'all',
[string]$Track = 'RHCSA9'
)

$scenarioList = @($ScenarioCatalog)
if ($Filter -eq 'labs') {
$scenarioList = @($scenarioList | Where-Object { $_.Category -ne 'exams' })
}
elseif ($Filter -eq 'exams') {
$scenarioList = @($scenarioList | Where-Object { $_.Category -eq 'exams' })
}

if ($scenarioList.Count -eq 0) {
return @((Get-UiHeading -Text 'No scenarios found' -StyleName 'Warning'))
}

$labList = @($scenarioList | Where-Object { $_.Category -ne 'exams' } | Sort-Object Id)
$examList = @($scenarioList | Where-Object { $_.Category -eq 'exams' } | Sort-Object Id)

$summary = switch ($Filter) {
'labs' { '{0} objective labs' -f $labList.Count }
'exams' { '{0} mock exams' -f $examList.Count }
default { '{0} scenarios | {1} labs | {2} exams' -f $scenarioList.Count, $labList.Count, $examList.Count }
}

$headerContent = @(
(Format-UiKeyValue -Key 'Track' -Value (Format-StyledText -Text (ConvertTo-ScenarioTrack -Track $Track).ToUpperInvariant() -StyleName 'Accent')),
(Format-UiKeyValue -Key 'Total' -Value (Format-StyledText -Text $summary -StyleName 'Muted'))
)

$catalogPanelWidth = [Math]::Max(
(Get-ScenarioCatalogPanelWidth -ScenarioList $labList -Minimum 54),
(Get-ScenarioCatalogPanelWidth -ScenarioList $examList -Minimum 54)
)

$lines = @(Format-UiPanel -Title 'Scenarios' -TitleStyle 'Header' -ContentLines $headerContent -MinWidth $catalogPanelWidth)
$lines += ''

if ($labList.Count -gt 0) {
$lines += Format-ScenarioCatalogTable -SectionTitle 'Labs' -SectionStyleName 'Lab' -ScenarioList $labList -PanelWidth $catalogPanelWidth
$lines += ''
}

if ($examList.Count -gt 0) {
$lines += Format-ScenarioCatalogTable -SectionTitle 'Exams' -SectionStyleName 'Exam' -ScenarioList $examList -PanelWidth $catalogPanelWidth
}

return $lines
}

function Format-ScenarioStatusOutput {
param(
[object]$ScenarioStatus
)

if ($null -eq $ScenarioStatus) {
return @(
(Get-UiHeading -Text 'No active scenario' -StyleName 'Warning')
)
}

$tasksPath = if ($ScenarioStatus.Mode -eq 'lab') { $ScenarioStatus.LabTasksDoc } else { $ScenarioStatus.ExamTasksDoc }
$solutionPath = if ($ScenarioStatus.Mode -eq 'lab') { $ScenarioStatus.LabSolutionDoc } else { $ScenarioStatus.ExamSolutionDoc }

$lines = @(
(Get-UiHeading -Text 'Active Scenario'),
(Format-UiLabelValue -Label 'Id' -Value $ScenarioStatus.ScenarioId),
(Format-UiLabelValue -Label 'Title' -Value $ScenarioStatus.Title),
(Format-UiLabelValue -Label 'Mode' -Value $ScenarioStatus.Mode),
(Format-UiLabelValue -Label 'Ends' -Value $ScenarioStatus.EndsAt),
(Format-UiLabelValue -Label 'Brief' -Value $ScenarioStatus.RunBrief),
(Format-UiLabelValue -Label 'Tasks' -Value $tasksPath),
(Format-UiLabelValue -Label 'Solution' -Value $solutionPath)
)

return $lines
}

function Format-VmStatusOutput {
param(
[object[]]$MachineStatus = @()
)

$statusList = @($MachineStatus)
if ($statusList.Count -eq 0) {
return @(Format-UiPanel -Title 'VMs' -TitleStyle 'Info' -ContentLines @(
(Format-StyledText -Text 'No Vagrant status data was returned for this project.' -StyleName 'Warning')
))
}

$rows = foreach ($machine in $statusList) {
[PSCustomObject]@{
Name = [string]$machine.Name
State = [string]$machine.StateHuman
}
}

$nameWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Name }) -Minimum 2
$stateWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.State }) -Minimum 5

$headerLine = '{0}  {1}' -f `
(Format-PaddedCell -Text 'VM' -Width $nameWidth -StyleName 'Accent'),
(Format-PaddedCell -Text 'STATE' -Width $stateWidth -StyleName 'Accent')

$separatorLine = Format-StyledText -Text ('{0}  {1}' -f `
('-' * $nameWidth), ('-' * $stateWidth)) -StyleName 'Muted'

$contentLines = @($headerLine, $separatorLine)

foreach ($row in $rows) {
$stateStyle = if ($row.State -eq 'running') { 'Success' } elseif ($row.State -eq 'not created') { 'Muted' } else { 'Warning' }
$contentLines += ('{0}  {1}' -f `
(Format-PaddedCell -Text $row.Name -Width $nameWidth -StyleName 'Accent'),
(Format-PaddedCell -Text $row.State -Width $stateWidth -StyleName $stateStyle))
}

return @(Format-UiPanel -Title 'VMs' -TitleStyle 'Info' -ContentLines $contentLines)
}

function Get-RhcsaAsciiBanner {
$face = @(
'4paI4paI4paI4paI4paI4paI4pWXIOKWiOKWiOKVlyAg4paI4paI4pWXIOKWiOKWiOKWiOKWiOKWiOKWiOKVl+KWiOKWiOKWiOKWiOKWiOKWiOKWiOKVlyDilojilojilojilojilojilZcgICAgIOKWiOKWiOKWiOKWiOKWiOKWiOKWiOKVl+KWiOKWiOKVl+KWiOKWiOKWiOKVlyAgIOKWiOKWiOKWiOKVl+KWiOKWiOKVlyAgIOKWiOKWiOKVl+KWiOKWiOKVlyAgICAgIOKWiOKWiOKWiOKWiOKWiOKVlyDilojilojilojilojilojilojilojilojilZcg4paI4paI4paI4paI4paI4paI4pWXIOKWiOKWiOKWiOKWiOKWiOKWiOKVlyA=',
'4paI4paI4pWU4pWQ4pWQ4paI4paI4pWX4paI4paI4pWRICDilojilojilZHilojilojilZTilZDilZDilZDilZDilZ3ilojilojilZTilZDilZDilZDilZDilZ3ilojilojilZTilZDilZDilojilojilZcgICAg4paI4paI4pWU4pWQ4pWQ4pWQ4pWQ4pWd4paI4paI4pWR4paI4paI4paI4paI4pWXIOKWiOKWiOKWiOKWiOKVkeKWiOKWiOKVkSAgIOKWiOKWiOKVkeKWiOKWiOKVkSAgICAg4paI4paI4pWU4pWQ4pWQ4paI4paI4pWX4pWa4pWQ4pWQ4paI4paI4pWU4pWQ4pWQ4pWd4paI4paI4pWU4pWQ4pWQ4pWQ4paI4paI4pWX4paI4paI4pWU4pWQ4pWQ4paI4paI4pWX',
'4paI4paI4paI4paI4paI4paI4pWU4pWd4paI4paI4paI4paI4paI4paI4paI4pWR4paI4paI4pWRICAgICDilojilojilojilojilojilojilojilZfilojilojilojilojilojilojilojilZEgICAg4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWR4paI4paI4pWU4paI4paI4paI4paI4pWU4paI4paI4pWR4paI4paI4pWRICAg4paI4paI4pWR4paI4paI4pWRICAgICDilojilojilojilojilojilojilojilZEgICDilojilojilZEgICDilojilojilZEgICDilojilojilZHilojilojilojilojilojilojilZTilZ0=',
'4paI4paI4pWU4pWQ4pWQ4paI4paI4pWX4paI4paI4pWU4pWQ4pWQ4paI4paI4pWR4paI4paI4pWRICAgICDilZrilZDilZDilZDilZDilojilojilZHilojilojilZTilZDilZDilojilojilZEgICAg4pWa4pWQ4pWQ4pWQ4pWQ4paI4paI4pWR4paI4paI4pWR4paI4paI4pWR4pWa4paI4paI4pWU4pWd4paI4paI4pWR4paI4paI4pWRICAg4paI4paI4pWR4paI4paI4pWRICAgICDilojilojilZTilZDilZDilojilojilZEgICDilojilojilZEgICDilojilojilZEgICDilojilojilZHilojilojilZTilZDilZDilojilojilZc=',
'4paI4paI4pWRICDilojilojilZHilojilojilZEgIOKWiOKWiOKVkeKVmuKWiOKWiOKWiOKWiOKWiOKWiOKVl+KWiOKWiOKWiOKWiOKWiOKWiOKWiOKVkeKWiOKWiOKVkSAg4paI4paI4pWRICAgIOKWiOKWiOKWiOKWiOKWiOKWiOKWiOKVkeKWiOKWiOKVkeKWiOKWiOKVkSDilZrilZDilZ0g4paI4paI4pWR4pWa4paI4paI4paI4paI4paI4paI4pWU4pWd4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWRICDilojilojilZEgICDilojilojilZEgICDilZrilojilojilojilojilojilojilZTilZ3ilojilojilZEgIOKWiOKWiOKVkQ==',
'4pWa4pWQ4pWdICDilZrilZDilZ3ilZrilZDilZ0gIOKVmuKVkOKVnSDilZrilZDilZDilZDilZDilZDilZ3ilZrilZDilZDilZDilZDilZDilZDilZ3ilZrilZDilZ0gIOKVmuKVkOKVnSAgICDilZrilZDilZDilZDilZDilZDilZDilZ3ilZrilZDilZ3ilZrilZDilZ0gICAgIOKVmuKVkOKVnSDilZrilZDilZDilZDilZDilZDilZ0g4pWa4pWQ4pWQ4pWQ4pWQ4pWQ4pWQ4pWd4pWa4pWQ4pWdICDilZrilZDilZ0gICDilZrilZDilZ0gICAg4pWa4pWQ4pWQ4pWQ4pWQ4pWQ4pWdIOKVmuKVkOKVnSAg4pWa4pWQ4pWd'
) | ForEach-Object {
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
}

$lines = @()
foreach ($line in $face) {
$lines += (Format-StyledText -Text $line -StyleName 'Brand')
}
return $lines
}

function Format-DashboardOutput {
param(
[Parameter(Mandatory = $true)]
[object]$BaselineStatus,
[AllowNull()]
[object]$ScenarioStatus = $null,
[string]$ProjectProfile = 'rhel9',
[string]$ScenarioTrack = 'rhcsa9'
)

$vmSummary = @($BaselineStatus.MachineStatus | ForEach-Object { '{0} {1}' -f $_.Name, $_.StateHuman }) -join ' | '
$scenarioSummary = if ($null -eq $ScenarioStatus) {
Format-StyledText -Text 'No active scenario' -StyleName 'Muted'
}
else {
'{0} ({1})' -f $ScenarioStatus.ScenarioId, $ScenarioStatus.Mode
}

$stateStyle = switch ([string]$BaselineStatus.State) {
'ready' { 'Success' }
'available' { 'Accent' }
'incomplete' { 'Warning' }
default { 'Muted' }
}

$contentLines = @(
(Format-UiKeyValue -Key 'Profile' -Value $ProjectProfile.ToUpperInvariant()),
(Format-UiKeyValue -Key 'Track' -Value (Format-StyledText -Text $ScenarioTrack.ToUpperInvariant() -StyleName 'Accent')),
(Format-UiKeyValue -Key 'Baseline' -Value (Format-StyledText -Text $BaselineStatus.StateText -StyleName $stateStyle)),
(Format-UiKeyValue -Key 'VMs' -Value $vmSummary),
(Format-UiKeyValue -Key 'Scenario' -Value $scenarioSummary)
)

return @(Format-UiPanel -Title 'RHCSA Status' -TitleStyle 'Header' -ContentLines $contentLines)
}

function Format-BaselineStartOutput {
param(
[object]$BaselineResult,
[object]$BaselineStatus
)

if ($null -eq $BaselineResult) {
return @((Get-UiHeading -Text 'Baseline start skipped' -StyleName 'Warning'))
}

$noticeList = @()
if ($BaselineResult.PSObject.Properties.Match('Notices').Count -gt 0) {
$noticeList = @($BaselineResult.Notices)
}

$lines = @()
foreach ($notice in $noticeList) {
$lines += ('{0} {1}' -f (Format-StyledText -Text 'NOTICE' -StyleName 'Warning'), $notice)
}

$wasSkipped = $false
if ($BaselineResult.PSObject.Properties.Match('Skipped').Count -gt 0) {
$wasSkipped = [bool]$BaselineResult.Skipped
}

if ($wasSkipped) {
$lines += (Get-UiHeading -Text 'Baseline start skipped' -StyleName 'Warning')
return $lines
}

return $lines
}

function Format-BaselineAlreadyRunningOutput {
param(
[object[]]$MachineStatus = @(),
[object]$ScenarioStatus = $null
)

$lines = @(
(Get-UiHeading -Text 'Simulator already running' -StyleName 'Info')
) + @(Format-VmStatusOutput -MachineStatus $MachineStatus)

if ($null -ne $ScenarioStatus) {
$lines += (Format-UiLabelValue -Label 'Scenario' -Value ([string]$ScenarioStatus.ScenarioId))
}

return $lines
}

function Format-ResumeOutput {
param(
[object]$ResumeResult
)

if ($null -eq $ResumeResult) {
return @((Get-UiHeading -Text 'Resume skipped' -StyleName 'Warning'))
}

$status = ''
if ($ResumeResult.PSObject.Properties.Match('Status').Count -gt 0) {
$status = [string]$ResumeResult.Status
}

$heading = switch ($status) {
'already-running' { Get-UiHeading -Text 'VMs already running' -StyleName 'Info' }
'resumed' { Get-UiHeading -Text 'VMs resumed' -StyleName 'Success' }
'not-built' { Get-UiHeading -Text 'Simulator not built' -StyleName 'Warning' }
'skipped' { Get-UiHeading -Text 'Resume skipped' -StyleName 'Warning' }
default { Get-UiHeading -Text 'VM status' -StyleName 'Info' }
}

$lines = @($heading)
if ($status -eq 'not-built') {
$lines += (Format-StyledText -Text 'Run .\RHCSA.ps1 up to build the clean baseline first.' -StyleName 'Muted')
}

if ($ResumeResult.PSObject.Properties.Match('MachineStatus').Count -gt 0) {
$lines += @(Format-VmStatusOutput -MachineStatus @($ResumeResult.MachineStatus))
}

return $lines
}

function Format-LeaveOutput {
param(
[object]$LeaveResult
)

if ($null -eq $LeaveResult -or $LeaveResult.PSObject.Properties.Match('Status').Count -eq 0) {
return @((Get-UiHeading -Text 'No active lab or exam' -StyleName 'Info'))
}

if ([string]$LeaveResult.Status -in @('left', 'exited')) {
return @((Get-UiHeading -Text ("Exited {0}" -f $LeaveResult.ScenarioId) -StyleName 'Success'))
}

return @((Get-UiHeading -Text 'No active lab or exam' -StyleName 'Info'))
}

function Format-ScenarioStartOutput {
param(
[object]$ScenarioResult
)

if ($null -eq $ScenarioResult) {
return @((Get-UiHeading -Text 'Scenario start skipped' -StyleName 'Warning'))
}

$tasksPath = if ($ScenarioResult.Mode -eq 'lab') { $ScenarioResult.Manifest.Docs.LabTasksRelative } else { $ScenarioResult.Manifest.Docs.ExamTasksRelative }
$solutionPath = if ($ScenarioResult.Mode -eq 'lab') { $ScenarioResult.Manifest.Docs.LabSolutionRelative } else { $ScenarioResult.Manifest.Docs.ExamSolutionRelative }
$alreadyActive = $false
if ($ScenarioResult.PSObject.Properties.Match('AlreadyActive').Count -gt 0) {
$alreadyActive = [bool]$ScenarioResult.AlreadyActive
}
$headingTemplate = if ($alreadyActive) { 'Already active: {0}' } else { 'Started {0}' }
$headingStyle = if ($alreadyActive) { 'Info' } else { 'Success' }

$lines = @(
(Get-UiHeading -Text ($headingTemplate -f $ScenarioResult.Manifest.Id) -StyleName $headingStyle),
(Format-UiLabelValue -Label 'Title' -Value $ScenarioResult.Manifest.Title),
(Format-UiLabelValue -Label 'Mode' -Value $ScenarioResult.Mode),
(Format-UiLabelValue -Label 'Brief' -Value $ScenarioResult.RunArtifact.GeneratedArtifact.RunBrief)
)

$replacedActiveRun = $null
if ($ScenarioResult.PSObject.Properties.Match('ReplacedActiveRun').Count -gt 0) {
$replacedActiveRun = $ScenarioResult.ReplacedActiveRun
}

if ($null -ne $replacedActiveRun -and -not [string]::IsNullOrWhiteSpace([string]$replacedActiveRun.RunId)) {
if (-not $alreadyActive) {
$lines += (Format-UiLabelValue -Label 'Replaced' -Value $replacedActiveRun.ScenarioId)
}
}

$lines += (Format-UiLabelValue -Label 'Tasks' -Value $tasksPath)
$lines += (Format-UiLabelValue -Label 'Solution' -Value $solutionPath)

if ($alreadyActive) {
$lines += (Format-StyledText -Text 'Use reset to restart the current scenario from a clean baseline.' -StyleName 'Info')
}

if ($ScenarioResult.Manifest.Flags.PasswordRecovery) {
$lines += (Format-StyledText -Text 'Recovery mode uses the client GUI console.' -StyleName 'Warning')
}

return $lines
}

function Format-ScenarioResetOutput {
param(
[object]$ScenarioResult
)

if ($null -eq $ScenarioResult) {
return @((Get-UiHeading -Text 'Scenario reset skipped' -StyleName 'Warning'))
}

return @(
(Get-UiHeading -Text 'Reset complete' -StyleName 'Success'),
(Format-UiLabelValue -Label 'Brief' -Value $ScenarioResult.RunArtifact.GeneratedArtifact.RunBrief)
)
}

function Get-ExerciseCheckSummaryLabel {
param(
[string]$Command
)

$lowered = ([string]$Command).ToLowerInvariant()
switch -Regex ($lowered) {
'repomd\.xml|/etc/yum\.repos\.d|dnf -q repolist|baseos|appstream' { return 'repository check' }
'ls -zd /root|admin_home_t|restorecon|autorelabel' { return 'selinux relabel check' }
'passwordauthentication|permitrootlogin|/etc/ssh/sshd_config|sshd -t|sshd -T' { return 'ssh access check' }
'hostnamectl|--static' { return 'hostname check' }
'/etc/hosts|getent hosts' { return 'hosts entry check' }
'nmcli|ipv4\.addresses|ipv4\.gateway|ipv4\.dns|ipv4\.method|connection\.autoconnect' { return 'network profile check' }
'systemctl' { return 'service check' }
'firewall-cmd|semanage|getenforce' { return 'security check' }
'podman|container' { return 'container check' }
'mount|findmnt|/etc/fstab|swapon' { return 'storage check' }
'useradd|groupadd|chage|getent passwd' { return 'user check' }
default { return 'check' }
}
}

function Format-ExerciseCheckOutput {
param(
[object]$CheckResult
)

if ($null -eq $CheckResult) {
return @((Get-UiHeading -Text 'Check skipped' -StyleName 'Warning'))
}

$mode = 'lab'
if ($CheckResult.PSObject.Properties.Match('Mode').Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$CheckResult.Mode)) {
$mode = [string]$CheckResult.Mode
}

if ($CheckResult.NoChecks) {
$noun = if ($mode -eq 'exam') { 'exam' } else { 'lab' }
return @(
(Get-UiHeading -Text 'No automated checks' -StyleName 'Warning'),
(Format-StyledText -Text "This $noun does not define automated checks yet" -StyleName 'Muted')
)
}

$failedResults = @($CheckResult.Results | Where-Object { -not $_.Passed })
if ($failedResults.Count -eq $CheckResult.TotalCount -and $failedResults.Count -gt 0) {
$transportFailures = @(
$failedResults | Where-Object {
$joined = ((@($_.StdOut) + @($_.StdErr)) -join "`n")
$joined -match '`ssh` executable not found in any directories in the %PATH% variable'
}
)

if ($transportFailures.Count -eq $failedResults.Count) {
return @(
(Get-UiHeading -Text 'Check unavailable' -StyleName 'Warning'),
(Format-StyledText -Text 'Vagrant could not locate ssh.exe for non-interactive validation in this PowerShell session.' -StyleName 'Muted'),
(Format-StyledText -Text 'Open a normal PowerShell window with ssh.exe on PATH, or run vagrant ssh manually for this host.' -StyleName 'Muted')
)
}
}

$resultText = if ($CheckResult.Passed) {
Format-StyledText -Text ("complete ({0}/{1})" -f $CheckResult.PassedCount, $CheckResult.TotalCount) -StyleName 'Success'
}
else {
Format-StyledText -Text ("incomplete ({0}/{1})" -f $CheckResult.PassedCount, $CheckResult.TotalCount) -StyleName 'Warning'
}
$label = if ($mode -eq 'exam') { 'Exam' } else { 'Lab' }
$lines = @(
(Format-UiLabelValue -Label $label -Value $CheckResult.ScenarioId),
(Format-UiLabelValue -Label 'Result' -Value $resultText)
)

if ($mode -eq 'exam') {
$score = 0
if ($CheckResult.PSObject.Properties.Match('Score').Count -gt 0) {
$score = [int]$CheckResult.Score
}
$lines += (Format-UiLabelValue -Label 'Exam checks' -Value ("{0}/{1}" -f $CheckResult.PassedCount, $CheckResult.TotalCount))
$lines += (Format-UiLabelValue -Label 'Score' -Value ("{0}/100" -f $score))
}

foreach ($result in @($CheckResult.Results)) {
$statusText = if ($result.Passed) { '[ok]' } else { '[fail]' }
$statusStyle = if ($result.Passed) { 'Success' } else { 'Warning' }
$displayCommand = if ([string]::IsNullOrWhiteSpace([string]$result.OriginalCommand)) { [string]$result.Command } else { [string]$result.OriginalCommand }
$label = Get-ExerciseCheckSummaryLabel -Command $displayCommand
$summary = if ($result.Passed) { "$label passed" } else { "$label failed" }
$lines += ('{0} [{1}] {2}' -f (Format-StyledText -Text $statusText -StyleName $statusStyle), $result.Target, $summary)
}

return $lines
}

function Format-RepoHealthOutput {
param(
[object]$RepoHealthResult
)

if ($null -eq $RepoHealthResult) {
return @((Get-UiHeading -Text 'Repo check skipped' -StyleName 'Warning'))
}

$resultText = if ($RepoHealthResult.Passed) {
Format-StyledText -Text 'available' -StyleName 'Success'
}
else {
Format-StyledText -Text 'unavailable' -StyleName 'Warning'
}

$lines = @(
(Format-UiLabelValue -Label 'Repo' -Value $resultText)
)

foreach ($result in @($RepoHealthResult.Results)) {
$statusText = if ($result.Passed) { '[ok]' } else { '[fail]' }
$statusStyle = if ($result.Passed) { 'Success' } else { 'Warning' }
$summary = if ($result.Passed) { 'repo reachable' } else { 'repo unreachable' }
$lines += ('{0} [{1}] {2}' -f (Format-StyledText -Text $statusText -StyleName $statusStyle), $result.MachineName, $summary)
}

return $lines
}

function Format-VmSshOutput {
param(
[object]$SessionResult
)

if ($null -eq $SessionResult) {
return @()
}

if ($SessionResult.PSObject.Properties.Match('Detached').Count -gt 0 -and [bool]$SessionResult.Detached) {
return @(
(Get-UiHeading -Text 'SSH session opened' -StyleName 'Success'),
(Format-UiLabelValue -Label 'VM' -Value ([string]$SessionResult.MachineName)),
(Format-StyledText -Text 'A new PowerShell window was opened for the interactive SSH session.' -StyleName 'Muted')
)
}

return @()
}

function Format-DestroyOutput {
param(
[object]$DestroyResult
)

$resultObject = $DestroyResult
if ($DestroyResult -is [System.Array]) {
$resultObject = @($DestroyResult | Where-Object { $null -ne $_ -and $_.PSObject.Properties['Skipped'] }) | Select-Object -Last 1
if ($null -eq $resultObject) {
$resultObject = [PSCustomObject]@{
Skipped = $false
Notes = @()
RemovedPaths = @()
}
}
}

$alreadyClean = $false
if ($null -ne $resultObject.PSObject.Properties['AlreadyClean']) {
$alreadyClean = [bool]$resultObject.AlreadyClean
}

$lines = @()
if ($resultObject.Skipped) {
$lines += (Get-UiHeading -Text 'Destroy skipped' -StyleName 'Warning')
return $lines
}

if ($alreadyClean) {
$lines += (Get-UiHeading -Text 'Simulator destroyed and cleaned' -StyleName 'Success')
return $lines
}

foreach ($note in @($resultObject.Notes)) {
$lines += ('{0} {1}' -f (Format-StyledText -Text 'NOTICE' -StyleName 'Warning'), $note)
}

$cleanupComplete = $true
if ($null -ne $resultObject.PSObject.Properties['CleanupComplete']) {
$cleanupComplete = [bool]$resultObject.CleanupComplete
}

if (-not $cleanupComplete) {
$lines += (Get-UiHeading -Text 'Destroy incomplete' -StyleName 'Warning')
return $lines
}

$lines += (Get-UiHeading -Text 'Simulator destroyed and cleaned' -StyleName 'Success')
return $lines
}

Export-ModuleMember -Function *
