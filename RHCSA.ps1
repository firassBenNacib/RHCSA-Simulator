[CmdletBinding(PositionalBinding = $true)]
param(
    [Parameter(Position = 0)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete)
        $null = $commandName, $parameterName

        foreach ($value in @('help', 'up', 'down', 'destroy', 'list', 'start', 'reset', 'status', 'check', 'repo', 'vms', 'ssh', 'ssh-config', 'tui', 'completion', '-h', '--help')) {
            if ($value -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
            }
        }
    })]
    [string]$Area,

    [Parameter(Position = 1)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $null = $commandName, $parameterName, $commandAst

        $area = [string]$fakeBoundParameters['Area']
        $candidates = switch ($area.ToLowerInvariant()) {
            'help' { @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion') }
            'list' { @('all', 'labs', 'lab', 'exams', 'exam') }
            'ssh' { @('client', 'server') }
            'ssh-config' { @('client', 'server') }
            'completion' { @('powershell', 'install') }
            default { @() }
        }

        foreach ($value in $candidates) {
            if ($value -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
            }
        }
    })]
    [string]$Command,

    [Parameter(Position = 2)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $null = $commandName, $parameterName, $commandAst

        $area = [string]$fakeBoundParameters['Area']
        $command = [string]$fakeBoundParameters['Command']
        $candidates = @()

        switch ("$($area.ToLowerInvariant())/$($command.ToLowerInvariant())") {
            'list/' {
                $candidates = @('all', 'labs', 'lab', 'exams', 'exam')
            }
            'ssh/' {
                $candidates = @('server', 'client')
            }
            'ssh-config/' {
                $candidates = @('server', 'client')
            }
        }

        foreach ($value in $candidates) {
            if ($value -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
            }
        }
    })]
    [string]$Item,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Extra,

    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst)
        $null = $commandName, $parameterName

        $scriptRoot = Split-Path -Parent $commandAst.Extent.File
        $scenarioRoot = Join-Path $scriptRoot 'scenarios'
        if (-not (Test-Path $scenarioRoot -PathType Container)) {
            return
        }

        $ids = @(Get-ChildItem -Path $scenarioRoot -Filter 'scenario.json' -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    ($_.Directory.Name)
                }
                catch {
                    $null
                }
            } |
            Sort-Object -Unique)

        foreach ($value in $ids) {
            if ($value -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
            }
        }
    })]
    [string]$Id,

    [ValidateSet('Lab', 'Exam')]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete)
        $null = $commandName, $parameterName

        foreach ($value in @('Lab', 'Exam')) {
            if ($value -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
            }
        }
    })]
    [string]$Mode = 'Lab',

    [ValidateSet('RHCSA9', 'RHCSA10', 'All', 'rhcsa9', 'rhcsa10', 'all')]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete)
        $null = $commandName, $parameterName

        foreach ($value in @('RHCSA9', 'RHCSA10', 'All')) {
            if ($value -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
            }
        }
    })]
    [string]$Track = 'RHCSA9',

    [ValidateSet('server', 'client', 'servervm', 'clientvm')]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete)
        $null = $commandName, $parameterName

        foreach ($value in @('server', 'client', 'servervm', 'clientvm')) {
            if ($value -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($value, $value, 'ParameterValue', $value)
            }
        }
    })]
    [string]$Vm,

    [Alias('h')]
    [switch]$Help,

    [switch]$NoProvision,
    [switch]$NormalStart,
    [switch]$HeadlessClient,
    [switch]$RealisticMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'host/simulator_common.ps1')
$script:ShowWorkflowStatus = $false

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

function ConvertTo-VmName {
    param(
        [string]$Name
    )

    $value = if ([string]::IsNullOrWhiteSpace($Name)) { 'client' } else { $Name.ToLowerInvariant() }
    switch ($value) {
        'servervm' { return 'server' }
        'clientvm' { return 'client' }
        'server' { return 'server' }
        default { return 'client' }
    }
}

function Get-RecommendedHelpCommand {
    param(
        [string]$Area,
        [string]$Command
    )

    switch ("$Area/$Command") {
        'baseline/up' { return '.\RHCSA.ps1 help up' }
        'baseline/down' { return '.\RHCSA.ps1 help down' }
        'baseline/destroy' { return '.\RHCSA.ps1 help destroy' }
        'scenario/list' { return '.\RHCSA.ps1 help list' }
        'scenario/start' { return '.\RHCSA.ps1 help start' }
        'scenario/check' { return '.\RHCSA.ps1 help check' }
        'baseline/repo' { return '.\RHCSA.ps1 help repo' }
        'scenario/reset' { return '.\RHCSA.ps1 help reset' }
        'dashboard/status' { return '.\RHCSA.ps1 help status' }
        'vm/status' { return '.\RHCSA.ps1 help vms' }
        'vm/ssh' { return '.\RHCSA.ps1 help ssh' }
        'vm/ssh-config' { return '.\RHCSA.ps1 help ssh-config' }
        'app/tui' { return '.\RHCSA.ps1 help tui' }
        'completion/manage' { return '.\RHCSA.ps1 help completion' }
        default { return '.\RHCSA.ps1 help' }
    }
}

function Format-ErrorOutput {
    param(
        [string]$Message
    )

    return @('{0} {1}' -f (Format-StyledText -Text 'Error:' -StyleName 'Warning'), $Message)
}

function Format-HelpUsageLine {
    param(
        [string]$CommandText
    )

    return 'Usage: {0}' -f (Format-StyledText -Text $CommandText -StyleName 'Command')
}

function Format-HelpEntryList {
    param(
        [object[]]$Entry
    )

    $nameWidth = Get-MaxCellWidth -Value ($Entry | ForEach-Object { $_.Name }) -Minimum 4
    $lines = @()
    foreach ($item in @($Entry)) {
        $lines += ('  {0}  {1}' -f (Format-PaddedCell -Text $item.Name -Width $nameWidth -StyleName 'Accent'), $item.Description)
    }

    return $lines
}

function Get-HelpOutput {
    param(
        [ValidateSet('general', 'up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion')]
        [string]$Scope = 'general'
    )

    switch ($Scope) {
        'up' {
            return @(
                (Get-UiHeading -Text 'up'),
                (Format-StyledText -Text 'Start or refresh the clean baseline.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 up [-NoProvision] [-NormalStart] [-HeadlessClient] [-RealisticMode]'),
                '',
                'Options:',
                '  -NoProvision    Start both VMs without guest provisioning',
                '  -NormalStart    Compatibility switch; normal behavior is already the default',
                '  -HeadlessClient Compatibility switch for older workflows',
                '  -RealisticMode  Compatibility switch for older workflows',
                '',
                'Examples:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 up'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 up -NoProvision')
            )
        }
        'down' {
            return @(
                (Get-UiHeading -Text 'down'),
                (Format-StyledText -Text 'Power off the simulator VMs without destroying the baseline or local state.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 down'),
                '',
                'Example:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 down')
            )
        }
        'destroy' {
            return @(
                (Get-UiHeading -Text 'destroy'),
                (Format-StyledText -Text 'Destroy both VMs and clean local simulator state.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 destroy'),
                '',
                'Example:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 destroy')
            )
        }
        'list' {
            return @(
                (Get-UiHeading -Text 'list'),
                (Format-StyledText -Text 'List available labs and mock exams.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 list [labs|exams] [-Track RHCSA9|RHCSA10|All]'),
                '',
                'Examples:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 list'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 list labs'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 list exams')
            )
        }
        'start' {
            return @(
                (Get-UiHeading -Text 'start'),
                (Format-StyledText -Text 'Start a lab or exam run.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 start -Id <scenario-id> -Mode <Lab|Exam> [-Track RHCSA9|RHCSA10|All]'),
                '',
                'Options:',
                '  -Id     Scenario id to start',
                '  -Mode   Lab or Exam',
                '  -Track  Scenario track, default RHCSA9',
                '',
                'Examples:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 start -Id lab-01-networking-hostname -Mode Lab'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 start -Id mock-exam-a -Mode Exam')
            )
        }
        'check' {
            return @(
                (Get-UiHeading -Text 'check'),
                (Format-StyledText -Text 'Run the automated checks for the active lab.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 check [-Id <lab-id>]'),
                '',
                'Example:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 check')
            )
        }
        'repo' {
            return @(
                (Get-UiHeading -Text 'repo'),
                (Format-StyledText -Text 'Run the offline package repository self-test on server and client.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 repo'),
                '',
                'Example:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 repo')
            )
        }
        'reset' {
            return @(
                (Get-UiHeading -Text 'reset'),
                (Format-StyledText -Text 'Reset the active run back to the clean baseline and reapply its overlay.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 reset'),
                '',
                'Example:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 reset')
            )
        }
        'status' {
            return @(
                (Get-UiHeading -Text 'status'),
                (Format-StyledText -Text 'Show baseline, VM state, and the active scenario.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 status')
            )
        }
        'vms' {
            return @(
                (Get-UiHeading -Text 'vms'),
                (Format-StyledText -Text 'Show VM state for server and client.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 vms')
            )
        }
        'ssh' {
            return @(
                (Get-UiHeading -Text 'ssh'),
                (Format-StyledText -Text 'Open an SSH session. Defaults to client.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 ssh [server|client]'),
                '',
                (Format-StyledText -Text 'On Windows this opens a dedicated PowerShell window for the session.' -StyleName 'Muted'),
                '',
                'Examples:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh server')
            )
        }
        'ssh-config' {
            return @(
                (Get-UiHeading -Text 'ssh-config'),
                (Format-StyledText -Text 'Print SSH config for external SSH clients. Defaults to client.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 ssh-config [server|client]'),
                '',
                'Examples:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh-config'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh-config server')
            )
        }
        'tui' {
            return @(
                (Get-UiHeading -Text 'tui'),
                (Format-StyledText -Text 'Open the labs-first interactive terminal UI.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 tui [-Track RHCSA9|RHCSA10|All]'),
                '',
                'Example:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 tui'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 tui -Track RHCSA10')
            )
        }
        'completion' {
            return @(
                (Get-UiHeading -Text 'completion'),
                (Format-StyledText -Text 'Generate or install PowerShell tab completion for commands, lab ids, modes, and VM names.' -StyleName 'Muted'),
                (Format-HelpUsageLine -CommandText '.\RHCSA.ps1 completion <powershell|install>'),
                '',
                'Examples:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 completion powershell'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 completion install')
            )
        }
        default {
            $entry = @(
                [PSCustomObject]@{ Name = 'up'; Description = 'Start or refresh the clean baseline' }
                [PSCustomObject]@{ Name = 'down'; Description = 'Power off the simulator VMs' }
                [PSCustomObject]@{ Name = 'destroy'; Description = 'Destroy VMs and local simulator state' }
                [PSCustomObject]@{ Name = 'list'; Description = 'List labs and mock exams' }
                [PSCustomObject]@{ Name = 'start'; Description = 'Start a lab or exam run' }
                [PSCustomObject]@{ Name = 'check'; Description = 'Run checks for the active lab' }
                [PSCustomObject]@{ Name = 'repo'; Description = 'Run the offline repo self-test' }
                [PSCustomObject]@{ Name = 'reset'; Description = 'Reset the active run' }
                [PSCustomObject]@{ Name = 'status'; Description = 'Show baseline, VMs, and active scenario' }
                [PSCustomObject]@{ Name = 'vms'; Description = 'Show VM state' }
                [PSCustomObject]@{ Name = 'ssh'; Description = 'Open an SSH session' }
                [PSCustomObject]@{ Name = 'ssh-config'; Description = 'Print SSH config for external clients' }
                [PSCustomObject]@{ Name = 'tui'; Description = 'Open the interactive TUI' }
                [PSCustomObject]@{ Name = 'completion'; Description = 'Generate or install PowerShell completion' }
            )
            return @(
                (Get-UiHeading -Text 'RHCSA Simulator'),
                (Format-StyledText -Text 'Usage: .\RHCSA.ps1 <command> [args]' -StyleName 'Muted'),
                '',
                'Commands:',
                (Format-HelpEntryList -Entry $entry),
                '',
                (Format-StyledText -Text 'Help: .\RHCSA.ps1 help <command>' -StyleName 'Muted'),
                '',
                'Examples:',
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 up'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 down'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 list labs'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 start -Id lab-01-networking-hostname -Mode Lab'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 ssh'),
                (Format-UiCommandLine -CommandText '.\RHCSA.ps1 tui')
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
                throw "Unknown start argument '$token'."
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
        throw "Unknown list argument '$($commandItem[1])'."
    }

    if ($commandItem.Count -eq 1) {
        switch ($commandItem[0].ToLowerInvariant()) {
            'all' { $option.Filter = 'all' }
            'lab' { $option.Filter = 'labs' }
            'labs' { $option.Filter = 'labs' }
            'exam' { $option.Filter = 'exams' }
            'exams' { $option.Filter = 'exams' }
            default { throw "Unknown list argument '$($commandItem[0])'." }
        }
    }

    return $option
}

function Get-PowerShellCompletionScript {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $scriptPath = (Join-Path $ProjectRoot 'RHCSA.ps1').Replace("'", "''")
    $scenarioRoot = (Join-Path $ProjectRoot 'scenarios').Replace("'", "''")

    return @"
`$rhcsaScriptPath = '$scriptPath'
`$rhcsaScenarioRoot = '$scenarioRoot'

Register-ArgumentCompleter -CommandName '.\RHCSA.ps1', 'RHCSA.ps1' -ScriptBlock {
    param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)
    `$null = `$commandName, `$parameterName, `$fakeBoundParameters

    function New-RhcsaCompletionResult {
        param([string]`$Value)
        [System.Management.Automation.CompletionResult]::new(`$Value, `$Value, 'ParameterValue', `$Value)
    }

    function Complete-RhcsaValues {
        param([string[]]`$Value)
        foreach (`$item in @(`$Value | Where-Object { -not [string]::IsNullOrWhiteSpace(`$_) } | Sort-Object -Unique)) {
            if (`$item -like "`$wordToComplete*") {
                New-RhcsaCompletionResult -Value `$item
            }
        }
    }

    function Get-RhcsaScenarioIds {
        param([switch]`$LabsOnly)
        if (-not (Test-Path `$rhcsaScenarioRoot -PathType Container)) {
            return @()
        }

        if (`$LabsOnly) {
            return @(Get-ChildItem -Path (Join-Path `$rhcsaScenarioRoot 'labs') -Filter 'scenario.json' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { `$_.Directory.Name } | Sort-Object -Unique)
        }

        return @(Get-ChildItem -Path `$rhcsaScenarioRoot -Filter 'scenario.json' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { `$_.Directory.Name } | Sort-Object -Unique)
    }

    `$elements = @(`$commandAst.CommandElements | ForEach-Object { `$_.Extent.Text })
    if (`$elements.Count -eq 0) {
        return
    }

    `$tokens = @()
    if (`$elements.Count -gt 1) {
        `$tokens = @(`$elements[1..(`$elements.Count - 1)] | Where-Object { -not [string]::IsNullOrWhiteSpace(`$_) })
    }

    if (`$tokens.Count -gt 0 -and `$tokens[-1] -eq `$wordToComplete) {
        if (`$tokens.Count -eq 1) {
            `$tokens = @()
        }
        else {
            `$tokens = @(`$tokens[0..(`$tokens.Count - 2)])
        }
    }

    if (`$tokens.Count -eq 0) {
        Complete-RhcsaValues -Value @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion', 'help')
        return
    }

    `$root = `$tokens[0].ToLowerInvariant()
    `$last = if (`$tokens.Count -gt 0) { [string]`$tokens[-1] } else { '' }

    switch (`$root) {
        'help' {
            Complete-RhcsaValues -Value @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion')
            return
        }
        'list' {
            if (`$tokens.Count -le 1) {
                Complete-RhcsaValues -Value @('labs', 'exams', '-Track')
            }
            elseif (`$last -eq '-Track') {
                Complete-RhcsaValues -Value @('RHCSA9', 'RHCSA10', 'All')
            }
            return
        }
        'ssh' {
            if (`$tokens.Count -le 1) {
                Complete-RhcsaValues -Value @('client', 'server')
            }
            return
        }
        'ssh-config' {
            if (`$tokens.Count -le 1) {
                Complete-RhcsaValues -Value @('client', 'server')
            }
            return
        }
        'completion' {
            if (`$tokens.Count -le 1) {
                Complete-RhcsaValues -Value @('powershell', 'install')
            }
            return
        }
        'start' {
            if (`$last -eq '-Id') {
                Complete-RhcsaValues -Value (Get-RhcsaScenarioIds)
                return
            }
            if (`$last -eq '-Mode') {
                Complete-RhcsaValues -Value @('Lab', 'Exam')
                return
            }
            if (`$last -eq '-Track') {
                Complete-RhcsaValues -Value @('RHCSA9', 'RHCSA10', 'All')
                return
            }
            Complete-RhcsaValues -Value @('-Id', '-Mode', '-Track')
            return
        }
        'tui' {
            if (`$last -eq '-Track') {
                Complete-RhcsaValues -Value @('RHCSA9', 'RHCSA10', 'All')
                return
            }
            Complete-RhcsaValues -Value @('-Track')
            return
        }
        'check' {
            if (`$last -eq '-Id') {
                Complete-RhcsaValues -Value (Get-RhcsaScenarioIds -LabsOnly)
                return
            }
            Complete-RhcsaValues -Value @('-Id')
            return
        }
    }
}
"@
}

function Install-PowerShellCompletion {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $startMarker = '# >>> RHCSA simulator completion >>>'
    $endMarker = '# <<< RHCSA simulator completion <<<'
    $completionBlock = @(
        $startMarker,
        (Get-PowerShellCompletionScript -ProjectRoot $ProjectRoot),
        $endMarker
    ) -join [Environment]::NewLine

    $profilePath = $PROFILE.CurrentUserCurrentHost
    $profileDirectory = Split-Path -Parent $profilePath
    if (-not (Test-Path $profileDirectory)) {
        New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    }

    $currentContent = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { '' }
    $pattern = '(?s)' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker)
    if ($currentContent -match $pattern) {
        $updatedContent = [regex]::Replace($currentContent, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{
            param($match)
            $null = $match
            $completionBlock
        })
    }
    elseif ([string]::IsNullOrWhiteSpace($currentContent)) {
        $updatedContent = $completionBlock
    }
    else {
        $updatedContent = ($currentContent.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $completionBlock)
    }

    Set-Utf8NoBomFile -Path $profilePath -Content $updatedContent
    return $profilePath
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

    $lines = @(
        (Get-UiHeading -Text 'Scenarios'),
        (Format-StyledText -Text ("Track: {0}" -f (ConvertTo-ScenarioTrack -Track $Track).ToUpperInvariant()) -StyleName 'Muted'),
        (Format-StyledText -Text $summary -StyleName 'Muted'),
        ''
    )

    if ($labList.Count -gt 0) {
        $lines += Format-ScenarioCatalogTable -SectionTitle 'Labs' -SectionStyleName 'Lab' -ScenarioList $labList
    }

    if ($examList.Count -gt 0) {
        $lines += Format-ScenarioCatalogTable -SectionTitle 'Exams' -SectionStyleName 'Exam' -ScenarioList $examList
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
        return @(
            (Get-UiHeading -Text 'VMs'),
            (Format-StyledText -Text 'No Vagrant status data was returned for this project.' -StyleName 'Warning')
        )
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
        ('-' * $nameWidth),
        ('-' * $stateWidth)) -StyleName 'Muted'

    $lines = @(
        (Get-UiHeading -Text 'VMs'),
        '',
        $headerLine,
        $separatorLine
    )

    foreach ($row in $rows) {
        $stateStyle = if ($row.State -eq 'running') { 'Success' } elseif ($row.State -eq 'not created') { 'Muted' } else { 'Warning' }
        $lines += ('{0}  {1}' -f `
            (Format-PaddedCell -Text $row.Name -Width $nameWidth -StyleName 'Accent'),
            (Format-PaddedCell -Text $row.State -Width $stateWidth -StyleName $stateStyle))
    }

    return $lines
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
    $lines += (Format-StyledText -Text 'Made by Firas Ben Nacib' -StyleName 'Accent')
    return $lines
}

function Format-DashboardOutput {
    param(
        [Parameter(Mandatory = $true)]
        [object]$BaselineStatus,
        [AllowNull()]
        [object]$ScenarioStatus = $null
    )

    $vmSummary = @($BaselineStatus.MachineStatus | ForEach-Object { '{0} {1}' -f $_.Name, $_.StateHuman }) -join ' | '
    $scenarioSummary = if ($null -eq $ScenarioStatus) {
        'No active scenario'
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

    return @(
        (Get-UiHeading -Text 'RHCSA'),
        (Format-UiLabelValue -Label 'Baseline' -Value (Format-StyledText -Text $BaselineStatus.StateText -StyleName $stateStyle)),
        (Format-UiLabelValue -Label 'VMs' -Value $vmSummary),
        (Format-UiLabelValue -Label 'Scenario' -Value $scenarioSummary)
    )
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

    $scenarioText = if ($BaselineResult.ClearedActiveRun) { 'No active scenario' } else { 'No active scenario' }

    $lines += @(
        (Get-UiHeading -Text 'Baseline ready' -StyleName 'Success'),
        (Format-UiLabelValue -Label 'VMs' -Value (@($BaselineStatus.MachineStatus | ForEach-Object { '{0} {1}' -f $_.Name, $_.StateHuman }) -join ' | ')),
        (Format-UiLabelValue -Label 'Scenario' -Value $scenarioText)
    )
    return $lines
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

    if ($CheckResult.NoChecks) {
        return @(
            (Get-UiHeading -Text 'No automated checks' -StyleName 'Warning'),
            (Format-StyledText -Text 'This lab does not define automated checks yet' -StyleName 'Muted')
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
    $lines = @(
        (Format-UiLabelValue -Label 'Lab' -Value $CheckResult.ScenarioId),
        (Format-UiLabelValue -Label 'Result' -Value $resultText)
    )

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

function Get-NonEmptyTokenList {
    param(
        [string[]]$Value = @()
    )

    return @($Value | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Resolve-CommandRoute {
    param(
        [string]$AreaValue,
        [string]$CommandValue,
        [string]$ItemValue,
        [string[]]$ExtraValue = @()
    )

    $resolvedArea = if ([string]::IsNullOrWhiteSpace($AreaValue)) { '' } else { $AreaValue.ToLowerInvariant() }
    $tokens = @(Get-NonEmptyTokenList -Value @($CommandValue, $ItemValue) + @($ExtraValue))

    switch ($resolvedArea) {
        'help' {
            if ($tokens.Count -gt 0 -and $tokens[0].ToLowerInvariant() -in @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion')) {
                $nextArea = $tokens[0].ToLowerInvariant()
                $remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
                return [PSCustomObject]@{ Area = 'help'; Command = $nextArea; Item = $null; Extra = $remaining; Legacy = $false }
            }
        }
        'up' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'up'; Item = $null; Extra = $tokens; Legacy = $false } }
        'down' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'down'; Item = $null; Extra = $tokens; Legacy = $false } }
        'destroy' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'destroy'; Item = $null; Extra = $tokens; Legacy = $false } }
        'list' {
            $listItem = if ($tokens.Count -gt 0) { $tokens[0] } else { $null }
            $remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
            return [PSCustomObject]@{ Area = 'scenario'; Command = 'list'; Item = $listItem; Extra = $remaining; Legacy = $false }
        }
        'start' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'start'; Item = $null; Extra = $tokens; Legacy = $false } }
        'repo' { return [PSCustomObject]@{ Area = 'baseline'; Command = 'repo'; Item = $null; Extra = $tokens; Legacy = $false } }
        'reset' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'reset'; Item = $null; Extra = $tokens; Legacy = $false } }
        'status' { return [PSCustomObject]@{ Area = 'dashboard'; Command = 'status'; Item = $null; Extra = $tokens; Legacy = $false } }
        'check' { return [PSCustomObject]@{ Area = 'scenario'; Command = 'check'; Item = $null; Extra = $tokens; Legacy = $false } }
        'vms' { return [PSCustomObject]@{ Area = 'vm'; Command = 'status'; Item = $null; Extra = $tokens; Legacy = $false } }
        'ssh' {
            $targetVm = if ($tokens.Count -gt 0) { $tokens[0] } else { 'client' }
            $remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
            return [PSCustomObject]@{ Area = 'vm'; Command = 'ssh'; Item = $targetVm; Extra = $remaining; Legacy = $false }
        }
        'ssh-config' {
            $targetVm = if ($tokens.Count -gt 0) { $tokens[0] } else { 'client' }
            $remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
            return [PSCustomObject]@{ Area = 'vm'; Command = 'ssh-config'; Item = $targetVm; Extra = $remaining; Legacy = $false }
        }
        'tui' { return [PSCustomObject]@{ Area = 'app'; Command = 'tui'; Item = $null; Extra = $tokens; Legacy = $false } }
        'completion' {
            $subcommand = if ($tokens.Count -gt 0) { $tokens[0] } else { $null }
            $remaining = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
            return [PSCustomObject]@{ Area = 'completion'; Command = 'manage'; Item = $subcommand; Extra = $remaining; Legacy = $false }
        }
    }

    return [PSCustomObject]@{
        Area = $resolvedArea
        Command = if ([string]::IsNullOrWhiteSpace($CommandValue)) { '' } else { $CommandValue.ToLowerInvariant() }
        Item = if ([string]::IsNullOrWhiteSpace($ItemValue)) { $null } else { $ItemValue }
        Extra = @(Get-NonEmptyTokenList -Value $ExtraValue)
        Legacy = ($resolvedArea -in @('baseline', 'scenario', 'vm'))
    }
}

$projectRoot = Get-ProjectRoot -Start $PSScriptRoot

if ($Help) {
    $helpScope = 'general'
    $normalizedArea = if ([string]::IsNullOrWhiteSpace($Area)) { '' } else { $Area.ToLowerInvariant() }
    $normalizedCommand = if ([string]::IsNullOrWhiteSpace($Command)) { '' } else { $Command.ToLowerInvariant() }

    switch ($normalizedArea) {
        '' { $helpScope = 'general' }
        'up' { $helpScope = 'up' }
        'down' { $helpScope = 'down' }
        'destroy' { $helpScope = 'destroy' }
        'list' { $helpScope = 'list' }
        'start' { $helpScope = 'start' }
        'check' { $helpScope = 'check' }
        'repo' { $helpScope = 'repo' }
        'reset' { $helpScope = 'reset' }
        'status' { $helpScope = 'status' }
        'vms' { $helpScope = 'vms' }
        'ssh' { $helpScope = 'ssh' }
        'ssh-config' { $helpScope = 'ssh-config' }
        'tui' { $helpScope = 'tui' }
        'completion' { $helpScope = 'completion' }
        'help' {
            $helpScope = if ($normalizedCommand -in @('up', 'down', 'destroy', 'list', 'start', 'check', 'repo', 'reset', 'status', 'vms', 'ssh', 'ssh-config', 'tui', 'completion')) {
                $normalizedCommand
            }
            else {
                'general'
            }
        }
        default { $helpScope = 'general' }
    }

    Get-HelpOutput -Scope $helpScope | Write-Output
    return
}

$route = Resolve-CommandRoute -AreaValue $Area -CommandValue $Command -ItemValue $Item -ExtraValue $Extra
$area = [string]$route.Area
$command = [string]$route.Command
$item = if ([string]::IsNullOrWhiteSpace([string]$route.Item)) { $null } else { [string]$route.Item }
$remainingItem = @($route.Extra)
$isLegacyRoute = [bool]$route.Legacy

try {
    if ($area -eq 'help') {
        if ($remainingItem.Count -gt 0) {
            throw "Unknown help argument '$($remainingItem[0])'."
        }

        $helpScope = if ([string]::IsNullOrWhiteSpace($command)) { 'general' } else { $command }
        Get-HelpOutput -Scope $helpScope | Write-Output
        return
    }

    if ([string]::IsNullOrWhiteSpace($area) -or (Test-HelpToken -Token $area)) {
        Get-HelpOutput -Scope 'general' | Write-Output
        return
    }

    if ($isLegacyRoute) {
        throw 'Unknown command. Run .\RHCSA.ps1 help for usage.'
    }

    switch ("$area/$command") {
        'baseline/up' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'up' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown up argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown up argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown up argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown up argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown up argument '-Vm'."
            }

            Write-Output ''
            Get-RhcsaAsciiBanner | Write-Output
            Write-Output ''
            $previousWorkflowPreference = $script:ShowWorkflowStatus
            $script:ShowWorkflowStatus = $true
            try {
                $result = Start-BaselineSession `
                    -NoProvision:$NoProvision `
                    -NormalStart:$NormalStart `
                    -HeadlessClient:$HeadlessClient `
                    -RealisticMode:$RealisticMode `
                    -ProjectRoot $projectRoot
            }
            finally {
                $script:ShowWorkflowStatus = $previousWorkflowPreference
            }
            Format-BaselineStartOutput -BaselineResult $result -BaselineStatus (Get-BaselineStatus -ProjectRoot $projectRoot) | Write-Output
            break
        }
        'baseline/down' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'down' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown down argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown down argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown down argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown down argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown down argument '-Vm'."
            }

            $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $projectRoot)
            $vagrantPath = Get-VagrantPath
            foreach ($machineName in @('server', 'client')) {
                $current = $machineStatus | Where-Object { $_.Name -eq $machineName } | Select-Object -First 1
                if ($null -eq $current) {
                    continue
                }
                if ($current.State -in @('not created', 'poweroff', 'saved', 'aborted')) {
                    continue
                }
                Invoke-ExternalCommand -FilePath $vagrantPath -ArgumentList @('halt', $machineName, '-f') -FailureMessage "Failed to halt $machineName." -IgnoreExitCode -SuppressOutput
            }

            Write-Output (Get-UiHeading -Text 'VMs powered off' -StyleName 'Success')
            Format-VmStatusOutput -MachineStatus (Get-VagrantMachineStatus -ProjectRoot $projectRoot) | Write-Output
            break
        }
        'baseline/repo' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'repo' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown repo argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown repo argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown repo argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown repo argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown repo argument '-Vm'."
            }

            $result = Test-BaselineOfflineRepoHealth -ProjectRoot $projectRoot
            Format-RepoHealthOutput -RepoHealthResult $result | Write-Output
            if (-not $result.Passed) {
                exit 1
            }
            break
        }
        'baseline/destroy' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'destroy' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown destroy argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown destroy argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown destroy argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown destroy argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown destroy argument '-Vm'."
            }

            $result = Remove-LabEnvironment -ProjectRoot $projectRoot
            Format-DestroyOutput -DestroyResult $result | Write-Output
            break
        }
        'scenario/list' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'list' | Write-Output
                break
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown list argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown list argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown list argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown list argument '-Vm'."
            }

            $listFilter = 'all'
            if ($item) {
                switch ($item.ToLowerInvariant()) {
                    'all' { $listFilter = 'all' }
                    'lab' { $listFilter = 'labs' }
                    'labs' { $listFilter = 'labs' }
                    'exam' { $listFilter = 'exams' }
                    'exams' { $listFilter = 'exams' }
                    default { throw "Unknown list argument '$item'." }
                }
            }

            Format-ScenarioCatalogOutput -ScenarioCatalog @(Get-ScenarioCatalog -ProjectRoot $projectRoot -Track $Track) -Filter $listFilter -Track $Track | Write-Output
            break
        }
        'scenario/start' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'start' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown start argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown start argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown start argument '-Vm'."
            }

            if (-not $PSBoundParameters.ContainsKey('Id') -or [string]::IsNullOrWhiteSpace($Id)) {
                throw 'Scenario start requires -Id <scenario-id>.'
            }

            $result = Start-ScenarioRun -ScenarioId $Id -Mode $Mode -Track $Track -ProjectRoot $projectRoot
            Format-ScenarioStartOutput -ScenarioResult $result | Write-Output
            break
        }
        'scenario/reset' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'reset' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown reset argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown reset argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown reset argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown reset argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown reset argument '-Vm'."
            }

            $status = Get-ScenarioStatus -ProjectRoot $projectRoot
            if ($null -eq $status) {
                throw 'No active run found. Start one first with .\RHCSA.ps1 start -Id <scenario-id> -Mode Lab.'
            }

            $result = Reset-ScenarioRun -ProjectRoot $projectRoot
            Format-ScenarioResetOutput -ScenarioResult $result | Write-Output
            break
        }
        'scenario/status' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'status' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown status argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown status argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown status argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown status argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown status argument '-Vm'."
            }

            Format-ScenarioStatusOutput -ScenarioStatus (Get-ScenarioStatus -ProjectRoot $projectRoot) | Write-Output
            break
        }
        'scenario/check' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'check' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown check argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown check argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown check argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown check argument '-Vm'."
            }

            $result = Invoke-LabExerciseCheck -ScenarioId $Id -ProjectRoot $projectRoot
            Format-ExerciseCheckOutput -CheckResult $result | Write-Output
            if (-not $result.Passed) {
                exit 1
            }
            break
        }
        'dashboard/status' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'status' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown status argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown status argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown status argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown status argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown status argument '-Vm'."
            }

            Format-DashboardOutput -BaselineStatus (Get-BaselineStatus -ProjectRoot $projectRoot) -ScenarioStatus (Get-ScenarioStatus -ProjectRoot $projectRoot) | Write-Output
            break
        }
        'vm/status' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'vms' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown vms argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown vms argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown vms argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown vms argument '-Mode'."
            }

            if ($PSBoundParameters.ContainsKey('Vm')) {
                throw "Unknown vms argument '-Vm'."
            }

            Format-VmStatusOutput -MachineStatus (Get-VagrantMachineStatus -ProjectRoot $projectRoot) | Write-Output
            break
        }
        'vm/ssh' {
            if ((-not $PSBoundParameters.ContainsKey('Vm')) -and $item -and (Test-HelpToken -Token $item)) {
                Get-HelpOutput -Scope 'ssh' | Write-Output
                break
            }
            if ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0])) {
                Get-HelpOutput -Scope 'ssh' | Write-Output
                break
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown ssh argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown ssh argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown ssh argument '-Mode'."
            }

            $targetVm = if ($PSBoundParameters.ContainsKey('Vm')) { $Vm } else { $item }
            if ([string]::IsNullOrWhiteSpace($targetVm)) {
                $targetVm = 'client'
            }

            if ($PSBoundParameters.ContainsKey('Vm') -and $item -and $item -ne $Vm) {
                throw "Conflicting ssh targets '$item' and '$Vm'."
            }

            $session = Open-VmSshSession -MachineName (ConvertTo-VmName -Name $targetVm) -ProjectRoot $projectRoot
            Format-VmSshOutput -SessionResult $session | Write-Output
            break
        }
        'vm/ssh-config' {
            if ((-not $PSBoundParameters.ContainsKey('Vm')) -and $item -and (Test-HelpToken -Token $item)) {
                Get-HelpOutput -Scope 'ssh-config' | Write-Output
                break
            }
            if ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0])) {
                Get-HelpOutput -Scope 'ssh-config' | Write-Output
                break
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown ssh-config argument '$($remainingItem[0])'."
            }

            if ($PSBoundParameters.ContainsKey('Id')) {
                throw "Unknown ssh-config argument '-Id'."
            }

            if ($PSBoundParameters.ContainsKey('Mode')) {
                throw "Unknown ssh-config argument '-Mode'."
            }

            $targetVm = if ($PSBoundParameters.ContainsKey('Vm')) { $Vm } else { $item }
            if ([string]::IsNullOrWhiteSpace($targetVm)) {
                $targetVm = 'client'
            }

            if ($PSBoundParameters.ContainsKey('Vm') -and $item -and $item -ne $Vm) {
                throw "Conflicting ssh-config targets '$item' and '$Vm'."
            }

            Get-VmSshConfig -MachineName (ConvertTo-VmName -Name $targetVm) -ProjectRoot $projectRoot | Write-Output
            break
        }
        'app/tui' {
            if (($item -and (Test-HelpToken -Token $item)) -or ($remainingItem.Count -eq 1 -and (Test-HelpToken -Token $remainingItem[0]))) {
                Get-HelpOutput -Scope 'tui' | Write-Output
                break
            }

            if ($item) {
                throw "Unknown tui argument '$item'."
            }

            if ($remainingItem.Count -gt 0) {
                throw "Unknown tui argument '$($remainingItem[0])'."
            }

            Open-RhcsaTui -ProjectRoot $projectRoot -Track $Track
            break
        }
        'completion/manage' {
            $completionCommand = if ([string]::IsNullOrWhiteSpace($item)) { 'help' } else { $item.ToLowerInvariant() }
            if ($remainingItem.Count -gt 0) {
                throw "Unknown completion argument '$($remainingItem[0])'."
            }

            if (Test-HelpToken -Token $completionCommand) {
                Get-HelpOutput -Scope 'completion' | Write-Output
                break
            }

            switch ($completionCommand) {
                'powershell' {
                    Get-PowerShellCompletionScript -ProjectRoot $projectRoot | Write-Output
                    break
                }
                'install' {
                    $profilePath = Install-PowerShellCompletion -ProjectRoot $projectRoot
                    Write-Output (Get-UiHeading -Text 'Completion installed' -StyleName 'Success')
                    Write-Output (Format-UiLabelValue -Label 'Profile' -Value $profilePath)
                    break
                }
                default {
                    throw "Unknown completion command '$completionCommand'."
                }
            }
            break
        }
        default {
            if ($area -eq 'completion') {
                throw 'Unknown completion command. Run .\RHCSA.ps1 help completion for usage.'
            }

            throw 'Unknown command. Run .\RHCSA.ps1 help for usage.'
        }
    }
}
catch {
    Format-ErrorOutput -Message $_.Exception.Message | Write-Output
    $recommendedHelp = if ($isLegacyRoute) {
        '.\RHCSA.ps1 help'
    }
    else {
        Get-RecommendedHelpCommand -Area $area -Command $command
    }
    Write-Output (Format-StyledText -Text ("Use: {0}" -f $recommendedHelp) -StyleName 'Muted')
    exit 1
}
