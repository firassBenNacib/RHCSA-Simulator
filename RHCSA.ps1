[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgumentList
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'host/simulator_common.ps1')

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
        'Header' { return "$escape[1;38;5;81m" }
        'Accent' { return "$escape[38;5;45m" }
        'Success' { return "$escape[1;38;5;42m" }
        'Warning' { return "$escape[1;38;5;214m" }
        'Muted' { return "$escape[38;5;245m" }
        'Command' { return "$escape[1;38;5;220m" }
        'Exam' { return "$escape[1;38;5;203m" }
        'Lab' { return "$escape[1;38;5;112m" }
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

function Format-UiCommandLine {
    param(
        [string]$CommandText
    )

    return '  {0} {1}' -f (Format-StyledText -Text '>' -StyleName 'Accent'), (Format-StyledText -Text $CommandText -StyleName 'Command')
}

function Format-UiLabelValue {
    param(
        [string]$Label,
        [string]$Value
    )

    return '  {0} {1}' -f (Format-StyledText -Text ("{0}:" -f $Label) -StyleName 'Accent'), $Value
}

function Test-HelpToken {
    param(
        [string]$Token
    )

    if ([string]::IsNullOrWhiteSpace($Token)) {
        return $false
    }

    return ($Token.ToLowerInvariant() -in @('help', '-h', '--help', '/?'))
}

function Get-RecommendedHelpCommand {
    param(
        [string]$Area
    )

    switch ($Area) {
        'baseline' { return '.\RHCSA.ps1 baseline help' }
        'scenario' { return '.\RHCSA.ps1 scenario help' }
        default { return '.\RHCSA.ps1 help' }
    }
}

function Format-ErrorOutput {
    param(
        [string]$Message,
        [string]$Area = ''
    )

    return @(
        (Get-UiHeading -Text 'Error' -StyleName 'Warning'),
        ('  {0}' -f $Message),
        '',
        (Get-UiHeading -Text 'Help'),
        (Format-UiCommandLine -CommandText (Get-RecommendedHelpCommand -Area $Area))
    )
}

function Get-HelpOutput {
    param(
        [ValidateSet('general', 'baseline', 'scenario')]
        [string]$Scope = 'general'
    )

    switch ($Scope) {
        'baseline' {
            return @(
                (Get-UiHeading -Text 'RHCSA Baseline Commands'),
                (Format-StyledText -Text 'Manage the clean Vagrant baseline and snapshot lifecycle.' -StyleName 'Muted'),
                '',
                (Get-UiHeading -Text 'Usage'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline help'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline up [options]'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline destroy'),
                '',
                (Get-UiHeading -Text 'Commands'),
                (Format-UiLabelValue -Label 'up' -Value 'Start or refresh servervm and clientvm, then update base-clean snapshots'),
                (Format-UiLabelValue -Label 'destroy' -Value 'Destroy the VMs and remove local simulator state'),
                '',
                (Get-UiHeading -Text 'Options For baseline up'),
                (Format-UiLabelValue -Label '-NoProvision' -Value 'Boot the VMs without running guest provisioning'),
                (Format-UiLabelValue -Label '-NormalStart' -Value 'Start the baseline without forcing realism behavior'),
                (Format-UiLabelValue -Label '-HeadlessClient' -Value 'Start clientvm without opening a GUI window'),
                (Format-UiLabelValue -Label '-RealisticMode' -Value 'Keep compatibility with the realism toggle when needed'),
                '',
                (Get-UiHeading -Text 'Examples'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline up'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline up -NoProvision'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline destroy')
            )
        }
        'scenario' {
            return @(
                (Get-UiHeading -Text 'RHCSA Scenario Commands'),
                (Format-StyledText -Text 'List, start, reset, and inspect RHCSA v9 labs and mock exams.' -StyleName 'Muted'),
                '',
                (Get-UiHeading -Text 'Usage'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario help'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario list [labs|exams|all]'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id <scenario-id> -Mode <Lab|Exam>'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario reset'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario status'),
                '',
                (Get-UiHeading -Text 'Commands'),
                (Format-UiLabelValue -Label 'list' -Value 'Show all scenarios or filter to labs or exams only'),
                (Format-UiLabelValue -Label 'start' -Value 'Restore the clean baseline, apply a scenario overlay, and generate the run brief'),
                (Format-UiLabelValue -Label 'reset' -Value 'Reset the active scenario back to its clean seeded state'),
                (Format-UiLabelValue -Label 'status' -Value 'Show the active scenario run and current run-brief path'),
                '',
                (Get-UiHeading -Text 'List Filters'),
                (Format-UiLabelValue -Label 'labs' -Value 'Show only objective labs'),
                (Format-UiLabelValue -Label 'exams' -Value 'Show only mock exams'),
                (Format-UiLabelValue -Label 'all' -Value 'Show the full catalog'),
                '',
                (Get-UiHeading -Text 'Examples'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario list'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario list exams'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario list labs'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id essential-tools -Mode Lab'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id mock-exam-a -Mode Exam'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario status')
            )
        }
        default {
            return @(
                (Get-UiHeading -Text 'RHCSA v9 Simulator'),
                (Format-StyledText -Text 'Windows + Vagrant + VirtualBox launcher for RHCSA v9 labs and mock exams.' -StyleName 'Muted'),
                '',
                (Get-UiHeading -Text 'Usage'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 help'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline <command>'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario <command>'),
                '',
                (Get-UiHeading -Text 'Areas'),
                (Format-UiLabelValue -Label 'baseline' -Value 'Manage the clean Vagrant baseline'),
                (Format-UiLabelValue -Label 'scenario' -Value 'Manage RHCSA labs and mock exams'),
                '',
                (Get-UiHeading -Text 'Common Commands'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline up'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline destroy'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario list'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id essential-tools -Mode Lab'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id mock-exam-a -Mode Exam'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario reset'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario status'),
                '',
                (Get-UiHeading -Text 'More Help'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 baseline help'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario help')
            )
        }
    }
}

function ConvertTo-StartOption {
    param(
        [string[]]$CommandArgument
    )

    $commandItem = @($CommandArgument)
    $option = @{
        Id = $null
        Mode = 'Lab'
    }

    for ($index = 0; $index -lt $commandItem.Count; $index++) {
        $token = $commandItem[$index]
        switch -Regex ($token.ToLowerInvariant()) {
            '^-id$' {
                if ($index + 1 -ge $commandItem.Count) {
                    throw 'Missing value for -Id.'
                }

                $option.Id = $commandItem[$index + 1]
                $index++
            }
            '^-mode$' {
                if ($index + 1 -ge $commandItem.Count) {
                    throw 'Missing value for -Mode.'
                }

                $option.Mode = $commandItem[$index + 1]
                $index++
            }
            default {
                throw "Unknown scenario start argument '$token'."
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($option.Id)) {
        throw 'Scenario start requires -Id <scenario-id>.'
    }

    if ($option.Mode -notin @('Lab', 'Exam', 'lab', 'exam')) {
        throw "Invalid scenario mode '$($option.Mode)'. Use Lab or Exam."
    }

    return $option
}

function ConvertTo-BaselineOption {
    param(
        [string[]]$CommandArgument
    )

    $commandItem = @($CommandArgument)
    $option = @{
        NoProvision = $false
        NormalStart = $false
        HeadlessClient = $false
        RealisticMode = $false
    }

    foreach ($token in $commandItem) {
        switch ($token.ToLowerInvariant()) {
            '-noprovision' { $option.NoProvision = $true }
            '-normalstart' { $option.NormalStart = $true }
            '-headlessclient' { $option.HeadlessClient = $true }
            '-realisticmode' { $option.RealisticMode = $true }
            default { throw "Unknown baseline argument '$token'." }
        }
    }

    return $option
}

function ConvertTo-ScenarioListOption {
    param(
        [string[]]$CommandArgument
    )

    $commandItem = @($CommandArgument)
    $option = @{
        Filter = 'all'
    }

    if ($commandItem.Count -gt 1) {
        throw "Unknown scenario list argument '$($commandItem[1])'."
    }

    if ($commandItem.Count -eq 1) {
        switch ($commandItem[0].ToLowerInvariant()) {
            'all' { $option.Filter = 'all' }
            'lab' { $option.Filter = 'labs' }
            'labs' { $option.Filter = 'labs' }
            'exam' { $option.Filter = 'exams' }
            'exams' { $option.Filter = 'exams' }
            default { throw "Unknown scenario list argument '$($commandItem[0])'." }
        }
    }

    return $option
}

function Get-MaxCellWidth {
    param(
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
        [object[]]$ScenarioList = @()
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
    $minutesWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Minutes }) -Minimum 3
    $titleWidth = Get-MaxCellWidth -Value ($rows | ForEach-Object { $_.Title }) -Minimum 5

    $headerLine = '{0}  {1}  {2}' -f `
        (Format-PaddedCell -Text 'ID' -Width $idWidth -StyleName 'Accent'),
        (Format-PaddedCell -Text 'MIN' -Width $minutesWidth -StyleName 'Accent'),
        (Format-PaddedCell -Text 'TITLE' -Width $titleWidth -StyleName 'Accent')

    $separatorLine = Format-StyledText -Text ('{0}  {1}  {2}' -f `
        ('-' * $idWidth),
        ('-' * $minutesWidth),
        ('-' * $titleWidth)) -StyleName 'Muted'

    $lines = @(
        (Get-UiHeading -Text $SectionTitle -StyleName $SectionStyleName),
        '',
        $headerLine,
        $separatorLine
    )

    foreach ($row in $rows) {
        $lines += ('{0}  {1}  {2}' -f `
            (Format-PaddedCell -Text $row.Id -Width $idWidth -StyleName 'Accent'),
            (Format-PaddedCell -Text $row.Minutes -Width $minutesWidth -StyleName 'Muted'),
            (Format-PaddedCell -Text $row.Title -Width $titleWidth))
    }

    $lines += ''
    return $lines
}

function Format-ScenarioCatalogOutput {
    param(
        [object[]]$ScenarioCatalog,
        [ValidateSet('all', 'labs', 'exams')]
        [string]$Filter = 'all'
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

    $lines = @(
        (Get-UiHeading -Text 'RHCSA v9 Scenario Catalog'),
        (Format-StyledText -Text $summary -StyleName 'Muted'),
        ''
    )

    if ($labList.Count -gt 0) {
        $lines += Format-ScenarioCatalogTable -SectionTitle 'Objective Labs' -SectionStyleName 'Lab' -ScenarioList $labList
    }

    if ($examList.Count -gt 0) {
        $lines += Format-ScenarioCatalogTable -SectionTitle 'Mock Exams' -SectionStyleName 'Exam' -ScenarioList $examList
    }

    if ($Filter -eq 'all') {
        $lines += (Get-UiHeading -Text 'Next Commands')
        $lines += (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id essential-tools -Mode Lab')
        $lines += (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id mock-exam-a -Mode Exam')
    }

    return $lines
}

function Format-ScenarioStatusOutput {
    param(
        [object]$ScenarioStatus
    )

    if ($null -eq $ScenarioStatus) {
        return @(
            (Get-UiHeading -Text 'No active scenario run' -StyleName 'Warning'),
            (Format-StyledText -Text 'Start one with .\RHCSA.ps1 scenario start -Id <id> -Mode <Lab|Exam>.' -StyleName 'Muted')
        )
    }

    $lines = @(
        (Get-UiHeading -Text 'Active Scenario Run'),
        (Format-UiLabelValue -Label 'Scenario' -Value $ScenarioStatus.ScenarioId),
        (Format-UiLabelValue -Label 'Category' -Value $ScenarioStatus.Category),
        (Format-UiLabelValue -Label 'Title' -Value $ScenarioStatus.Title),
        (Format-UiLabelValue -Label 'Mode' -Value $ScenarioStatus.Mode),
        (Format-UiLabelValue -Label 'Objectives' -Value ($ScenarioStatus.ObjectiveTags -join ', ')),
        (Format-UiLabelValue -Label 'Run Id' -Value $ScenarioStatus.RunId),
        (Format-UiLabelValue -Label 'Started' -Value $ScenarioStatus.StartedAt),
        (Format-UiLabelValue -Label 'Ends' -Value $ScenarioStatus.EndsAt),
        (Format-UiLabelValue -Label 'Artifacts' -Value $ScenarioStatus.ArtifactRoot),
        '',
        (Get-UiHeading -Text 'Run Brief'),
        ('  {0}' -f $ScenarioStatus.RunBrief)
    )

    $lines += ''
    $lines += (Get-UiHeading -Text 'Scenario Docs')
    if ($ScenarioStatus.Mode -eq 'lab') {
        $lines += ('  {0}' -f $ScenarioStatus.LabTasksDoc)
        $lines += ('  {0}' -f $ScenarioStatus.LabSolutionDoc)
    }
    else {
        $lines += ('  {0}' -f $ScenarioStatus.ExamTasksDoc)
        $lines += ('  {0}' -f $ScenarioStatus.ExamSolutionDoc)
    }

    return $lines
}

function Format-BaselineStartOutput {
    param(
        [object]$BaselineResult
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

    $lines += (Get-UiHeading -Text 'RHCSA v9 baseline ready' -StyleName 'Success')
    $lines += (Format-StyledText -Text 'servervm and clientvm are running with the clean baseline.' -StyleName 'Muted')
    $lines += ''
    $lines += (Get-UiHeading -Text 'Next Commands')
    $lines += (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario list')
    $lines += (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id essential-tools -Mode Lab')
    $lines += (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario start -Id mock-exam-a -Mode Exam')
    return $lines
}

function Format-ScenarioStartOutput {
    param(
        [object]$ScenarioResult
    )

    if ($null -eq $ScenarioResult) {
        return @((Get-UiHeading -Text 'Scenario start skipped' -StyleName 'Warning'))
    }

    $lines = @(
        (Get-UiHeading -Text ("Started {0}" -f $ScenarioResult.Manifest.Id) -StyleName 'Success'),
        (Format-UiLabelValue -Label 'Mode' -Value $ScenarioResult.Mode),
        (Format-UiLabelValue -Label 'Type' -Value $ScenarioResult.Manifest.Category),
        (Format-UiLabelValue -Label 'Title' -Value $ScenarioResult.Manifest.Title),
        (Format-UiLabelValue -Label 'Started' -Value $ScenarioResult.StartedAt.ToString('yyyy-MM-dd HH:mm:ss')),
        (Format-UiLabelValue -Label 'Ends' -Value $ScenarioResult.EndsAt.ToString('yyyy-MM-dd HH:mm:ss')),
        (Format-UiLabelValue -Label 'Reset Path' -Value $ScenarioResult.RestoreMethod),
        (Format-UiLabelValue -Label 'Artifacts' -Value $ScenarioResult.RunArtifact.RunRootRelative),
        '',
        (Get-UiHeading -Text 'Run Brief'),
        ('  {0}' -f $ScenarioResult.RunArtifact.GeneratedArtifact.RunBrief),
        ''
    )

    $lines += (Get-UiHeading -Text 'Scenario Docs')
    if ($ScenarioResult.Mode -eq 'lab') {
        $lines += ('  {0}' -f $ScenarioResult.Manifest.Docs.LabTasksRelative)
        $lines += ('  {0}' -f $ScenarioResult.Manifest.Docs.LabSolutionRelative)
    }
    else {
        $lines += ('  {0}' -f $ScenarioResult.Manifest.Docs.ExamTasksRelative)
        $lines += ('  {0}' -f $ScenarioResult.Manifest.Docs.ExamSolutionRelative)
    }
    $lines += ''

    if ($ScenarioResult.Manifest.Flags.PasswordRecovery) {
        $lines += (Format-StyledText -Text 'clientvm was restarted in GUI mode for password-recovery practice.' -StyleName 'Warning')
        $lines += (Format-StyledText -Text 'Vagrant SSH access to clientvm stays unavailable until you complete recovery and reboot normally.' -StyleName 'Muted')
    }
    elseif ($ScenarioResult.RestoreMethod -eq 'baseline-rebuild') {
        $lines += (Format-StyledText -Text 'Snapshot restore failed on this host, so the clean baseline was rebuilt and the scenario overlay was applied.' -StyleName 'Warning')
    }
    else {
        $lines += (Format-StyledText -Text 'Both VMs were restored to the clean baseline and the scenario overlay was applied.' -StyleName 'Muted')
    }

    $lines += ''
    $lines += (Get-UiHeading -Text 'Next Commands')
    $lines += (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario status')
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
        (Get-UiHeading -Text 'Scenario reset complete' -StyleName 'Success'),
        (Format-UiLabelValue -Label 'Run Id' -Value $ScenarioResult.RunArtifact.RunId),
        (Format-UiLabelValue -Label 'Artifacts' -Value $ScenarioResult.RunArtifact.RunRootRelative),
        '',
        (Get-UiHeading -Text 'Next Commands'),
        (Format-UiCommandLine -CommandText '.\RHCSA.ps1 scenario status')
    )
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

    $lines = @()
    foreach ($note in @($resultObject.Notes)) {
        if ([string]$note -match '^vagrant destroy returned exit code 1\b') {
            continue
        }
        $lines += ('{0} {1}' -f (Format-StyledText -Text 'NOTICE' -StyleName 'Warning'), $note)
    }

    if ($resultObject.Skipped) {
        $lines += (Get-UiHeading -Text 'Destroy skipped' -StyleName 'Warning')
        return $lines
    }

    $lines += (Get-UiHeading -Text 'Lab destroyed and cleaned.' -StyleName 'Success')
    return $lines
}

$projectRoot = Get-ProjectRoot -Start $PSScriptRoot
$cliArgument = @($ArgumentList | Where-Object { $null -ne $_ })
$area = if ($cliArgument.Count -ge 1) { $cliArgument[0].ToLowerInvariant() } else { '' }
$command = if ($cliArgument.Count -ge 2) { $cliArgument[1].ToLowerInvariant() } else { '' }
$remainingArgument = if ($cliArgument.Count -gt 2) { @($cliArgument[2..($cliArgument.Count - 1)]) } else { @() }
$remainingItem = @($remainingArgument)

try {
    if ($cliArgument.Count -eq 0 -or (Test-HelpToken -Token $area)) {
        Get-HelpOutput -Scope 'general' | Write-Output
        return
    }

    if ($area -eq 'baseline' -and ($cliArgument.Count -eq 1 -or (Test-HelpToken -Token $command))) {
        if ($remainingItem.Count -gt 0) {
            throw "Unknown baseline help argument '$($remainingItem[0])'."
        }

        Get-HelpOutput -Scope 'baseline' | Write-Output
        return
    }

    if ($area -eq 'scenario' -and ($cliArgument.Count -eq 1 -or (Test-HelpToken -Token $command))) {
        if ($remainingItem.Count -gt 0) {
            throw "Unknown scenario help argument '$($remainingItem[0])'."
        }

        Get-HelpOutput -Scope 'scenario' | Write-Output
        return
    }

    switch ("$area/$command") {
        'baseline/up' {
            $baselineOption = ConvertTo-BaselineOption -CommandArgument $remainingItem
            $result = Start-BaselineSession `
                -NoProvision:$baselineOption.NoProvision `
                -NormalStart:$baselineOption.NormalStart `
                -HeadlessClient:$baselineOption.HeadlessClient `
                -RealisticMode:$baselineOption.RealisticMode `
                -ProjectRoot $projectRoot
            Format-BaselineStartOutput -BaselineResult $result | Write-Output
            break
        }
        'baseline/destroy' {
            if ($remainingItem.Count -gt 0) {
                throw "Unknown baseline destroy argument '$($remainingItem[0])'."
            }

            $result = Remove-LabEnvironment -ProjectRoot $projectRoot
            Format-DestroyOutput -DestroyResult $result | Write-Output
            break
        }
        'scenario/list' {
            $listOption = ConvertTo-ScenarioListOption -CommandArgument $remainingItem
            Format-ScenarioCatalogOutput -ScenarioCatalog @(Get-ScenarioCatalog -ProjectRoot $projectRoot) -Filter $listOption.Filter | Write-Output
            break
        }
        'scenario/start' {
            $startOption = ConvertTo-StartOption -CommandArgument $remainingItem
            $result = Start-ScenarioRun -ScenarioId $startOption.Id -Mode $startOption.Mode -ProjectRoot $projectRoot
            Format-ScenarioStartOutput -ScenarioResult $result | Write-Output
            break
        }
        'scenario/reset' {
            if ($remainingItem.Count -gt 0) {
                throw "Unknown scenario reset argument '$($remainingItem[0])'."
            }

            $status = Get-ScenarioStatus -ProjectRoot $projectRoot
            if ($null -eq $status) {
                throw 'No active run found. Start a scenario first with .\RHCSA.ps1 scenario start.'
            }

            Write-Output ("Resetting scenario '{0}' in {1} mode..." -f $status.ScenarioId, $status.Mode)
            $result = Reset-ScenarioRun -ProjectRoot $projectRoot
            Format-ScenarioResetOutput -ScenarioResult $result | Write-Output
            break
        }
        'scenario/status' {
            if ($remainingItem.Count -gt 0) {
                throw "Unknown scenario status argument '$($remainingItem[0])'."
            }

            Format-ScenarioStatusOutput -ScenarioStatus (Get-ScenarioStatus -ProjectRoot $projectRoot) | Write-Output
            break
        }
        default {
            if ($area -eq 'baseline') {
                throw 'Unknown baseline command. Run .\RHCSA.ps1 baseline help for usage.'
            }

            if ($area -eq 'scenario') {
                throw 'Unknown scenario command. Run .\RHCSA.ps1 scenario help for usage.'
            }

            throw 'Unknown command. Run .\RHCSA.ps1 help for usage.'
        }
    }
}
catch {
    Format-ErrorOutput -Message $_.Exception.Message -Area $area | Write-Output
    exit 1
}
