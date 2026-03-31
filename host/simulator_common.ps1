Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ValidObjectiveTags = @(
    'essential-tools',
    'shell-scripting',
    'boot-and-recovery',
    'processes-logs-tuning',
    'storage-lvm',
    'filesystems-and-autofs',
    'software-scheduling-time',
    'networking-and-firewall',
    'users-sudo-ssh',
    'selinux-and-default-perms',
    'containers'
)

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

function Initialize-LabStateLayout {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $stateRoot = Get-LabStateRoot -ProjectRoot $ProjectRoot
    $runsRoot = Join-Path $stateRoot 'runs'

    foreach ($path in @($stateRoot, $runsRoot)) {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }

    return $stateRoot
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

function Get-ProjectRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $fullPath = (Resolve-Path $Path).Path
    $rootWithSeparator = $ProjectRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar

    if (-not $fullPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path '$fullPath' is outside project root '$ProjectRoot'."
    }

    return $fullPath.Substring($rootWithSeparator.Length).Replace('\', '/')
}

function Resolve-ProjectPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$RelativeOrAbsolutePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativeOrAbsolutePath)) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($RelativeOrAbsolutePath)) {
        return $RelativeOrAbsolutePath
    }

    return (Join-Path $BasePath $RelativeOrAbsolutePath)
}

function Get-RequiredProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [switch]$AllowZero
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        throw "Missing required property '$Name'."
    }

    $value = $property.Value
    if (-not $AllowZero -and ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)))) {
        throw "Property '$Name' must not be empty."
    }

    return $value
}

function Get-OptionalPropertyValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Get-StringArray {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [switch]$AllowEmpty
    )

    $items = @()
    foreach ($item in @($Value)) {
        if ($null -eq $item) {
            continue
        }

        $trimmed = ([string]$item).Trim()
        if ($trimmed.Length -eq 0) {
            continue
        }

        $items += $trimmed
    }

    if (-not $AllowEmpty -and $items.Count -eq 0) {
        throw "$Label must contain at least one entry."
    }

    return $items
}

function Resolve-ScenarioScriptPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioRoot,
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return [PSCustomObject]@{
            FullPath = $null
            RelativePath = $null
        }
    }

    $candidate = Resolve-ProjectPath -BasePath $ScenarioRoot -RelativeOrAbsolutePath $RelativePath
    if (-not (Test-Path $candidate -PathType Leaf)) {
        throw "Scenario file for $Label not found: $RelativePath"
    }

    $fullPath = (Resolve-Path $candidate).Path
    return [PSCustomObject]@{
        FullPath = $fullPath
        RelativePath = (Get-ProjectRelativePath -Path $fullPath -ProjectRoot $ProjectRoot)
    }
}

function Resolve-ScenarioDocPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioRoot,
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $candidate = Join-Path $ScenarioRoot $FileName
    if (-not (Test-Path $candidate -PathType Leaf)) {
        throw "Scenario file for $Label not found: $FileName"
    }

    $fullPath = (Resolve-Path $candidate).Path
    return [PSCustomObject]@{
        FullPath = $fullPath
        RelativePath = (Get-ProjectRelativePath -Path $fullPath -ProjectRoot $ProjectRoot)
    }
}

function ConvertTo-ScenarioManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $manifestFullPath = (Resolve-Path $ManifestPath).Path
    $scenarioRoot = Split-Path -Parent $manifestFullPath
    $relativeScenarioRoot = Get-ProjectRelativePath -Path $scenarioRoot -ProjectRoot $ProjectRoot
    $segments = $relativeScenarioRoot -split '/'

    if ($segments.Count -ne 3 -or $segments[0] -ne 'scenarios' -or $segments[1] -notin @('labs', 'exams')) {
        throw "Scenario root '$relativeScenarioRoot' must be in the form scenarios/labs/<id> or scenarios/exams/<id>."
    }

    $scenarioCategory = $segments[1]
    $scenarioFolderName = $segments[2]
    $raw = Get-Content $manifestFullPath -Raw | ConvertFrom-Json

    $id = [string](Get-RequiredProperty -Object $raw -Name 'id')
    if ($id -ne $scenarioFolderName) {
        throw "Scenario id '$id' must match folder name '$scenarioFolderName'."
    }

    $title = [string](Get-RequiredProperty -Object $raw -Name 'title')
    $description = [string](Get-RequiredProperty -Object $raw -Name 'description')
    $objectiveTags = Get-StringArray -Value (Get-RequiredProperty -Object $raw -Name 'objective_tags') -Label "Scenario '$id' objective_tags"
    $supportedModes = @(
        Get-StringArray -Value (Get-RequiredProperty -Object $raw -Name 'supported_modes') -Label "Scenario '$id' supported_modes" |
            ForEach-Object { $_.ToLowerInvariant() }
    )

    foreach ($tag in $objectiveTags) {
        if ($tag -notin $script:ValidObjectiveTags) {
            throw "Scenario '$id' has invalid objective tag '$tag'."
        }
    }

    foreach ($mode in $supportedModes) {
        if ($mode -notin @('lab', 'exam')) {
            throw "Scenario '$id' has invalid supported mode '$mode'."
        }
    }

    $timeLimit = [int](Get-RequiredProperty -Object $raw -Name 'time_limit_minutes' -AllowZero)
    if ($timeLimit -lt 0) {
        throw "Scenario '$id' time_limit_minutes must be zero or greater."
    }

    $flags = Get-RequiredProperty -Object $raw -Name 'flags'
    $passwordRecovery = [bool](Get-RequiredProperty -Object $flags -Name 'password_recovery' -AllowZero)
    $requiresServervm = [bool](Get-RequiredProperty -Object $flags -Name 'requires_servervm' -AllowZero)

    $vmScriptsRaw = Get-OptionalPropertyValue -Object $raw -Name 'vm_scripts'
    if ($null -eq $vmScriptsRaw) {
        $vmScriptsRaw = [PSCustomObject]@{}
    }

    $serverScript = Resolve-ScenarioScriptPath -ScenarioRoot $scenarioRoot -RelativePath ([string](Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'servervm')) -Label 'vm_scripts.servervm' -ProjectRoot $ProjectRoot
    $clientScript = Resolve-ScenarioScriptPath -ScenarioRoot $scenarioRoot -RelativePath ([string](Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'clientvm')) -Label 'vm_scripts.clientvm' -ProjectRoot $ProjectRoot
    $content = Get-RequiredProperty -Object $raw -Name 'content'
    $labContent = Get-OptionalPropertyValue -Object $content -Name 'lab'
    $examContent = Get-OptionalPropertyValue -Object $content -Name 'exam'

    if ('lab' -in $supportedModes -and $null -eq $labContent) {
        throw "Scenario '$id' supports lab mode but content.lab is missing."
    }

    if ('exam' -in $supportedModes -and $null -eq $examContent) {
        throw "Scenario '$id' supports exam mode but content.exam is missing."
    }

    $labTasksDoc = if ('lab' -in $supportedModes) {
        Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'LAB_TASKS.md' -Label 'LAB_TASKS.md' -ProjectRoot $ProjectRoot
    }
    else {
        [PSCustomObject]@{ FullPath = $null; RelativePath = $null }
    }

    $labSolutionDoc = if ('lab' -in $supportedModes) {
        Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'LAB_SOLUTION.md' -Label 'LAB_SOLUTION.md' -ProjectRoot $ProjectRoot
    }
    else {
        [PSCustomObject]@{ FullPath = $null; RelativePath = $null }
    }

    $examTasksDoc = if ('exam' -in $supportedModes) {
        Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'EXAM_TASKS.md' -Label 'EXAM_TASKS.md' -ProjectRoot $ProjectRoot
    }
    else {
        [PSCustomObject]@{ FullPath = $null; RelativePath = $null }
    }

    $examSolutionDoc = if ('exam' -in $supportedModes) {
        Resolve-ScenarioDocPath -ScenarioRoot $scenarioRoot -FileName 'EXAM_SOLUTION.md' -Label 'EXAM_SOLUTION.md' -ProjectRoot $ProjectRoot
    }
    else {
        [PSCustomObject]@{ FullPath = $null; RelativePath = $null }
    }

    $labTasks = @()
    $labHints = @()
    $labChecks = @()
    $labSolutionOutline = @()
    if ($null -ne $labContent) {
        $labTasks = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'tasks') -Label "Scenario '$id' content.lab.tasks"
        $labHints = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'hints' -AllowZero) -Label "Scenario '$id' content.lab.hints" -AllowEmpty
        $labChecks = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'checks' -AllowZero) -Label "Scenario '$id' content.lab.checks" -AllowEmpty
        $labSolutionOutline = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'solution_outline' -AllowZero) -Label "Scenario '$id' content.lab.solution_outline" -AllowEmpty
    }

    $examTasks = @()
    if ($null -ne $examContent) {
        $examTasks = Get-StringArray -Value (Get-RequiredProperty -Object $examContent -Name 'tasks') -Label "Scenario '$id' content.exam.tasks"
    }

    return [PSCustomObject]@{
        Id = $id
        Category = $scenarioCategory
        Title = $title
        Description = $description
        ObjectiveTags = $objectiveTags
        SupportedModes = $supportedModes
        TimeLimitMinutes = $timeLimit
        ScenarioRoot = $scenarioRoot
        RelativeScenarioRoot = $relativeScenarioRoot
        ManifestPath = $manifestFullPath
        RelativeManifestPath = (Get-ProjectRelativePath -Path $manifestFullPath -ProjectRoot $ProjectRoot)
        VmScripts = [PSCustomObject]@{
            Servervm = $serverScript.FullPath
            ServervmRelative = $serverScript.RelativePath
            Clientvm = $clientScript.FullPath
            ClientvmRelative = $clientScript.RelativePath
        }
        Docs = [PSCustomObject]@{
            LabTasks = $labTasksDoc.FullPath
            LabTasksRelative = $labTasksDoc.RelativePath
            LabSolution = $labSolutionDoc.FullPath
            LabSolutionRelative = $labSolutionDoc.RelativePath
            ExamTasks = $examTasksDoc.FullPath
            ExamTasksRelative = $examTasksDoc.RelativePath
            ExamSolution = $examSolutionDoc.FullPath
            ExamSolutionRelative = $examSolutionDoc.RelativePath
        }
        Flags = [PSCustomObject]@{
            PasswordRecovery = $passwordRecovery
            RequiresServervm = $requiresServervm
        }
        Content = [PSCustomObject]@{
            Lab = [PSCustomObject]@{
                Tasks = $labTasks
                Hints = $labHints
                Checks = $labChecks
                SolutionOutline = $labSolutionOutline
            }
            Exam = [PSCustomObject]@{
                Tasks = $examTasks
            }
        }
    }
}

function Get-ScenarioCatalog {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $scenariosRoot = Join-Path $ProjectRoot 'scenarios'
    if (-not (Test-Path $scenariosRoot -PathType Container)) {
        return @()
    }

    $manifestFiles = @(Get-ChildItem -Path $scenariosRoot -Filter 'scenario.json' -File -Recurse | Sort-Object FullName)
    $catalog = foreach ($file in $manifestFiles) {
        ConvertTo-ScenarioManifest -ManifestPath $file.FullName -ProjectRoot $ProjectRoot
    }

    return @($catalog | Sort-Object Category, Id)
}

function Get-ScenarioManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioId,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $matchingManifest = @(Get-ScenarioCatalog -ProjectRoot $ProjectRoot | Where-Object { $_.Id -eq $ScenarioId })
    if ($matchingManifest.Count -eq 0) {
        throw "Scenario '$ScenarioId' not found."
    }

    if ($matchingManifest.Count -gt 1) {
        throw "Scenario id '$ScenarioId' is duplicated in the scenario catalog."
    }

    return $matchingManifest[0]
}

function Format-NumberedSection {
    param(
        [string]$Title,
        [string[]]$Items
    )

    $lines = @($Title)
    if ($Items.Count -eq 0) {
        return @($lines + 'None')
    }

    for ($index = 0; $index -lt $Items.Count; $index++) {
        $lines += ('{0}. {1}' -f ($index + 1), $Items[$index])
    }

    return $lines
}

function Format-BulletedSection {
    param(
        [string]$Title,
        [string[]]$Items
    )

    $lines = @($Title)
    if ($Items.Count -eq 0) {
        return @($lines + 'None')
    }

    foreach ($item in $Items) {
        $lines += ('- {0}' -f $item)
    }

    return $lines
}

function Format-RunBriefText {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [Parameter(Mandatory = $true)]
        [ValidateSet('lab', 'exam')]
        [string]$Mode,
        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,
        [Parameter(Mandatory = $true)]
        [datetime]$EndsAt
    )

    $systems = if ($Manifest.Flags.RequiresServervm) { 'clientvm and servervm' } else { 'clientvm' }
    $lines = @(
        'RHCSA v9 Simulator Run Brief',
        ('Scenario: {0}' -f $Manifest.Id),
        ('Category: {0}' -f $Manifest.Category),
        ('Title: {0}' -f $Manifest.Title),
        ('Mode: {0}' -f $Mode),
        ('Objectives: {0}' -f ($Manifest.ObjectiveTags -join ', ')),
        ('Started: {0}' -f $StartedAt.ToString('yyyy-MM-dd HH:mm:ss')),
        ('Ends: {0}' -f $EndsAt.ToString('yyyy-MM-dd HH:mm:ss')),
        ('Systems: {0}' -f $systems),
        '',
        $Manifest.Description,
        ''
    )

    if ($Mode -eq 'lab') {
        $lines += Format-NumberedSection -Title 'Tasks' -Items $Manifest.Content.Lab.Tasks
        $lines += ''
        $lines += Format-BulletedSection -Title 'Hints' -Items $Manifest.Content.Lab.Hints
        $lines += ''
        $lines += Format-BulletedSection -Title 'Checks' -Items $Manifest.Content.Lab.Checks
        $lines += ''
        $lines += Format-BulletedSection -Title 'Solution Outline' -Items $Manifest.Content.Lab.SolutionOutline
    }
    else {
        $lines += Format-NumberedSection -Title 'Tasks' -Items $Manifest.Content.Exam.Tasks
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Export-RunArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [Parameter(Mandatory = $true)]
        [ValidateSet('lab', 'exam')]
        [string]$Mode,
        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,
        [Parameter(Mandatory = $true)]
        [datetime]$EndsAt,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $stateRoot = Initialize-LabStateLayout -ProjectRoot $ProjectRoot
    $runId = '{0}-{1}' -f $Manifest.Id, (Get-Date -Format 'yyyyMMdd-HHmmss')
    $runRoot = Join-Path (Join-Path $stateRoot 'runs') $runId

    if (Test-Path $runRoot) {
        Remove-Item -Path $runRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $runRoot | Out-Null

    $briefPath = Join-Path $runRoot 'run-brief.txt'
    Set-Utf8NoBomFile -Path $briefPath -Content (Format-RunBriefText -Manifest $Manifest -Mode $Mode -StartedAt $StartedAt -EndsAt $EndsAt)

    return [PSCustomObject]@{
        RunId = $runId
        RunRoot = $runRoot
        RunRootRelative = (Get-ProjectRelativePath -Path $runRoot -ProjectRoot $ProjectRoot)
        GeneratedArtifact = [PSCustomObject]@{
            RunBrief = (Get-ProjectRelativePath -Path $briefPath -ProjectRoot $ProjectRoot)
        }
    }
}

function Export-ActiveRunState {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [Parameter(Mandatory = $true)]
        [ValidateSet('lab', 'exam')]
        [string]$Mode,
        [Parameter(Mandatory = $true)]
        [object]$RunArtifact,
        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,
        [Parameter(Mandatory = $true)]
        [datetime]$EndsAt,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $state = [ordered]@{
        run_id = $RunArtifact.RunId
        status = 'active'
        mode = $Mode
        started_at = $StartedAt.ToString('o')
        ends_at = $EndsAt.ToString('o')
        artifact_root = $RunArtifact.RunRootRelative
        generated_artifacts = [ordered]@{
            run_brief = $RunArtifact.GeneratedArtifact.RunBrief
        }
        scenario = [ordered]@{
            id = $Manifest.Id
            category = $Manifest.Category
            title = $Manifest.Title
            description = $Manifest.Description
            objective_tags = $Manifest.ObjectiveTags
            supported_modes = $Manifest.SupportedModes
            time_limit_minutes = $Manifest.TimeLimitMinutes
            scenario_root = $Manifest.RelativeScenarioRoot
            manifest_path = $Manifest.RelativeManifestPath
            vm_scripts = [ordered]@{
                servervm = $Manifest.VmScripts.ServervmRelative
                clientvm = $Manifest.VmScripts.ClientvmRelative
            }
            docs = [ordered]@{
                lab_tasks = $Manifest.Docs.LabTasksRelative
                lab_solution = $Manifest.Docs.LabSolutionRelative
                exam_tasks = $Manifest.Docs.ExamTasksRelative
                exam_solution = $Manifest.Docs.ExamSolutionRelative
            }
            flags = [ordered]@{
                password_recovery = $Manifest.Flags.PasswordRecovery
                requires_servervm = $Manifest.Flags.RequiresServervm
            }
        }
    }

    $activeRunPath = Get-ActiveRunPath -ProjectRoot $ProjectRoot
    Set-Utf8NoBomFile -Path $activeRunPath -Content ($state | ConvertTo-Json -Depth 10)
    return $activeRunPath
}

function Export-BaseSnapshotState {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$MachineIdMap,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $state = [ordered]@{
        snapshot_name = 'base-clean'
        created_at = (Get-Date).ToString('o')
        machines = [ordered]@{}
    }

    foreach ($machineName in $MachineIdMap.Keys) {
        $state.machines[$machineName] = [ordered]@{
            vm_id = $MachineIdMap[$machineName]
        }
    }

    $statePath = Get-BaseSnapshotStatePath -ProjectRoot $ProjectRoot
    Set-Utf8NoBomFile -Path $statePath -Content ($state | ConvertTo-Json -Depth 10)
    return $statePath
}

function Get-BaseSnapshotState {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $statePath = Get-BaseSnapshotStatePath -ProjectRoot $ProjectRoot
    if (-not (Test-Path $statePath -PathType Leaf)) {
        return $null
    }

    $rawState = Get-Content $statePath -Raw
    if ($rawState.Length -gt 0 -and [int][char]$rawState[0] -eq 0xFEFF) {
        $rawState = $rawState.Substring(1)
    }

    return $rawState | ConvertFrom-Json
}

function Clear-ActiveRunState {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $activeRunPath = Get-ActiveRunPath -ProjectRoot $ProjectRoot
    if (Test-Path $activeRunPath -PathType Leaf) {
        Remove-Item -Path $activeRunPath -Force
    }
}

function Get-ActiveRunState {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $activeRunPath = Get-ActiveRunPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path $activeRunPath -PathType Leaf)) {
        return $null
    }

    $rawState = Get-Content $activeRunPath -Raw
    if ($rawState.Length -gt 0 -and [int][char]$rawState[0] -eq 0xFEFF) {
        $rawState = $rawState.Substring(1)
    }

    return $rawState | ConvertFrom-Json
}

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

function Get-NativeExitCode {
    param(
        [int]$Default = 0
    )

    if (Test-Path variable:LASTEXITCODE) {
        return $LASTEXITCODE
    }

    return $Default
}

function Write-WorkflowStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Area,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    [Console]::Out.WriteLine(('[{0}] {1}' -f $Area, $Message))
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

function Invoke-ExternalCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string[]]$ArgumentList = @()
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()

    try {
        $process = Start-Process `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        return [PSCustomObject]@{
            ExitCode = $process.ExitCode
            StdOut = @(Get-Content $stdoutPath -ErrorAction SilentlyContinue)
            StdErr = @(Get-Content $stderrPath -ErrorAction SilentlyContinue)
        }
    }
    finally {
        Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-ExternalCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string[]]$ArgumentList = @(),
        [string]$FailureMessage = 'Command failed.',
        [switch]$IgnoreExitCode,
        [switch]$PassThruExitCode,
        [switch]$SuppressOutput
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()

    $stdOut = @()
    $stdErr = @()

    try {
        $process = Start-Process `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        $exitCode = $process.ExitCode

        $stdOut = @(Get-Content $stdoutPath -ErrorAction SilentlyContinue)
        $stdErr = @(Get-Content $stderrPath -ErrorAction SilentlyContinue)
    }
    finally {
        Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }

    if (-not $SuppressOutput -and $exitCode -ne 0) {
        Write-FailureTranscript -StdOut $stdOut -StdErr $stdErr | Out-Null
    }

    if (-not $IgnoreExitCode -and $exitCode -ne 0) {
        $commandText = @($FilePath) + $ArgumentList
        throw "$FailureMessage Command: $($commandText -join ' ') Exit code: $exitCode"
    }

    if ($PassThruExitCode) {
        return $exitCode
    }
}

function Test-TransientVagrantFailure {
    param(
        [string[]]$StdOut = @(),
        [string[]]$StdErr = @()
    )

    $combinedOutput = ((@($StdOut) + @($StdErr)) -join "`n")
    if ([string]::IsNullOrWhiteSpace($combinedOutput)) {
        return $false
    }

    $patterns = @(
        'The SSH connection was unexpectedly closed by the remote end',
        'An error occurred in the underlying SSH library that Vagrant uses',
        'timeout during server version negotiating',
        'server version negotiating',
        'is not yet ready for SSH',
        'Connection reset by peer',
        'Connection closed by remote host',
        'Connection refused',
        'connection attempt timed out',
        'timed out while waiting for the machine to boot',
        'Timeout while waiting for the machine to boot'
    )

    foreach ($pattern in $patterns) {
        if ($combinedOutput -match $pattern) {
            return $true
        }
    }

    return $false
}

function Invoke-VagrantCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [string]$FailureMessage = 'Vagrant command failed.',
        [string]$RetryArea = 'baseline',
        [string]$RetryMessage = 'Retrying the Vagrant command after a transient SSH/provider failure',
        [int]$RetryCount = 2,
        [int]$RetryDelaySeconds = 15,
        [switch]$IgnoreExitCode,
        [switch]$PassThruExitCode,
        [switch]$SuppressOutput
    )

    $vagrantPath = Get-VagrantPath
    for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
        $result = Invoke-ExternalCapture -FilePath $vagrantPath -ArgumentList $ArgumentList
        if ($result.ExitCode -eq 0) {
            if ($PassThruExitCode) {
                return 0
            }

            return
        }

        $canRetry = $attempt -le $RetryCount -and (Test-TransientVagrantFailure -StdOut $result.StdOut -StdErr $result.StdErr)
        if ($canRetry) {
            Write-WorkflowStatus -Area $RetryArea -Message $RetryMessage
            Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
            continue
        }

        if (-not $SuppressOutput) {
            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
        }

        if (-not $IgnoreExitCode) {
            $commandText = @($vagrantPath) + $ArgumentList
            throw "$FailureMessage Command: $($commandText -join ' ') Exit code: $($result.ExitCode)"
        }

        if ($PassThruExitCode) {
            return $result.ExitCode
        }

        return
    }
}

function Get-VagrantMachineId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $idFile = Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\id"
    if (-not (Test-Path $idFile -PathType Leaf)) {
        throw "Vagrant machine id file not found for '$MachineName'."
    }

    $id = (Get-Content $idFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($id)) {
        throw "Vagrant machine id for '$MachineName' is empty."
    }

    return $id
}

function Get-OptionalVagrantMachineId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $idFile = Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\id"
    if (-not (Test-Path $idFile -PathType Leaf)) {
        return $null
    }

    $id = (Get-Content $idFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($id)) {
        return $null
    }

    return $id
}

function Get-VBoxSnapshotCatalog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('snapshot', $VmId, 'list', '--machinereadable')
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return @()
    }

    $snapshotNames = @()
    foreach ($line in $result.StdOut) {
        if ($line -match '^SnapshotName.*?="(.+)"$') {
            $snapshotNames += $matches[1]
        }
    }

    return $snapshotNames
}

function Wait-VBoxMachineReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [string]$VBoxManagePath = (Get-VBoxManagePath),
        [int]$TimeoutSeconds = 60
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('showvminfo', $VmId, '--machinereadable')
        if ($result.ExitCode -eq 0) {
            return
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    throw "VirtualBox VM '$VmId' remained locked for more than $TimeoutSeconds seconds."
}

function Get-VBoxMachineState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('showvminfo', $VmId, '--machinereadable')
    if ($result.ExitCode -ne 0) {
        return $null
    }

    foreach ($line in $result.StdOut) {
        if ($line -match '^VMState="(.+)"$') {
            return [string]$matches[1]
        }
    }

    return $null
}

function Wait-VBoxMachineState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [Parameter(Mandatory = $true)]
        [string[]]$DesiredState,
        [string]$VBoxManagePath = (Get-VBoxManagePath),
        [int]$TimeoutSeconds = 90
    )

    $expected = @($DesiredState | ForEach-Object { $_.ToLowerInvariant() })
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastState = $null

    do {
        $state = Get-VBoxMachineState -VmId $VmId -VBoxManagePath $VBoxManagePath
        if ($null -ne $state) {
            $lastState = [string]$state
            if ($lastState.ToLowerInvariant() -in $expected) {
                return $lastState
            }
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    $expectedLabel = $DesiredState -join ', '
    if ($lastState) {
        throw "VirtualBox VM '$VmId' did not reach state '$expectedLabel' within $TimeoutSeconds seconds. Last state: $lastState."
    }

    throw "VirtualBox VM '$VmId' did not reach state '$expectedLabel' within $TimeoutSeconds seconds."
}

function Stop-VBoxMachineForSnapshot {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$VBoxManagePath = (Get-VBoxManagePath),
        [string]$VagrantPath = (Get-VagrantPath)
    )

    if (-not $PSCmdlet.ShouldProcess($MachineName, 'Stop VM before snapshot operation')) {
        return
    }

    $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ($null -eq $vmId) {
        return
    }

    Invoke-ExternalCommand -FilePath $VagrantPath -ArgumentList @('halt', $MachineName, '-f') -FailureMessage "Failed to halt $MachineName." -IgnoreExitCode -SuppressOutput
    Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('controlvm', $vmId, 'poweroff') -FailureMessage "Failed to force power off $MachineName." -IgnoreExitCode -SuppressOutput

    try {
        Wait-VBoxMachineState -VmId $vmId -DesiredState @('poweroff', 'saved', 'aborted') -VBoxManagePath $VBoxManagePath -TimeoutSeconds 90 | Out-Null
    }
    catch {
        Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('controlvm', $vmId, 'poweroff') -FailureMessage "Failed to force power off $MachineName." -IgnoreExitCode -SuppressOutput
        Wait-VBoxMachineState -VmId $vmId -DesiredState @('poweroff', 'saved', 'aborted') -VBoxManagePath $VBoxManagePath -TimeoutSeconds 45 | Out-Null
    }

    Start-Sleep -Seconds 2
}

function Invoke-VBoxSnapshotCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VmId,
        [Parameter(Mandatory = $true)]
        [string[]]$SnapshotArgumentList,
        [Parameter(Mandatory = $true)]
        [string]$FailureMessage,
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        Wait-VBoxMachineReady -VmId $VmId -VBoxManagePath $VBoxManagePath

        try {
            Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList (@('snapshot', $VmId) + $SnapshotArgumentList) -FailureMessage $FailureMessage
            return
        }
        catch {
            $lastError = $_
            if ($attempt -ge 5) {
                throw
            }

            Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 10))
        }
    }

    if ($null -ne $lastError) {
        throw $lastError
    }
}

function Test-BaseSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vmId = Get-VagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    $state = Get-BaseSnapshotState -ProjectRoot $ProjectRoot
    if ($null -ne $state -and [string]$state.snapshot_name -eq 'base-clean') {
        $machineState = $state.machines.PSObject.Properties[$MachineName]
        if ($null -ne $machineState -and [string]$machineState.Value.vm_id -eq $vmId) {
            return $true
        }
    }

    return ('base-clean' -in (Get-VBoxSnapshotCatalog -VmId $vmId))
}

function Invoke-BaseSnapshotInitialization {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceRefresh
    )

    $vboxManage = Get-VBoxManagePath
    $vagrant = Get-VagrantPath
    $targetMachine = @()
    $machineIdMap = @{}

    foreach ($machine in @('servervm', 'clientvm')) {
        if (-not (Test-Path (Join-Path $ProjectRoot ".vagrant\machines\$machine\virtualbox\id"))) {
            throw "Cannot create base snapshots because '$machine' has not been created yet."
        }

        if ($ForceRefresh -or -not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
            $targetMachine += $machine
        }
    }

    if ($targetMachine.Count -eq 0) {
        return $false
    }

    Push-Location $ProjectRoot
    try {
        foreach ($machine in @('servervm', 'clientvm')) {
            Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage -VagrantPath $vagrant
        }

        foreach ($machine in $targetMachine) {
            $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            $machineIdMap[$machine] = $vmId
            if (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot) {
                Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('delete', 'base-clean') -FailureMessage "Failed to delete existing base-clean snapshot for $machine." -VBoxManagePath $vboxManage
            }
            Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('take', 'base-clean', '--description=RHCSA-v9-simulator-clean-baseline') -FailureMessage "Failed to create base-clean snapshot for $machine." -VBoxManagePath $vboxManage
        }

        foreach ($machine in @('servervm', 'clientvm')) {
            if (-not $machineIdMap.ContainsKey($machine)) {
                $machineIdMap[$machine] = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            }
        }

        Export-BaseSnapshotState -MachineIdMap $machineIdMap -ProjectRoot $ProjectRoot | Out-Null

        Invoke-VagrantCommand -ArgumentList @('up', 'servervm', '--no-provision', '--no-color') -FailureMessage 'Failed to restart servervm after snapshot creation.' -RetryArea 'baseline' -RetryMessage 'Retrying servervm startup after a transient SSH/provider failure'
        Invoke-VagrantCommand -ArgumentList @('up', 'clientvm', '--no-provision', '--no-color') -FailureMessage 'Failed to restart clientvm after snapshot creation.' -RetryArea 'baseline' -RetryMessage 'Retrying clientvm startup after a transient SSH/provider failure'
    }
    finally {
        Pop-Location
    }

    return $true
}

function Invoke-BaseSnapshotRestore {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath
    $vagrant = Get-VagrantPath

    Write-WorkflowStatus -Area 'scenario' -Message 'Restoring the clean baseline snapshots'

    Push-Location $ProjectRoot
    try {
        foreach ($machine in @('servervm', 'clientvm')) {
            Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage -VagrantPath $vagrant
        }

        foreach ($machine in @('servervm', 'clientvm')) {
            $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('restore', 'base-clean') -FailureMessage "Failed to restore snapshot 'base-clean' for $machine." -VBoxManagePath $vboxManage
        }

        Invoke-VagrantCommand -ArgumentList @('up', 'servervm', '--no-provision', '--no-color') -FailureMessage 'Failed to start servervm after restoring base snapshots.' -RetryArea 'scenario' -RetryMessage 'Retrying servervm startup after restoring the clean baseline'
        Invoke-VagrantCommand -ArgumentList @('up', 'clientvm', '--no-provision', '--no-color') -FailureMessage 'Failed to start clientvm after restoring base snapshots.' -RetryArea 'scenario' -RetryMessage 'Retrying clientvm startup after restoring the clean baseline'
    }
    finally {
        Pop-Location
    }
}

function Invoke-ScenarioProvisioning {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    Push-Location $ProjectRoot
    try {
        # Snapshot restore can report success just before the guest SSH service is
        # fully ready for a second Vagrant connection, especially on Windows hosts.
        Start-Sleep -Seconds 5

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ServervmRelative)) {
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the servervm overlay for '$($Manifest.Id)'"
            Invoke-VagrantCommand -ArgumentList @('provision', 'servervm', '--provision-with', 'scenario-server', '--no-color') -FailureMessage "Failed to apply server scenario overlay for '$($Manifest.Id)'." -RetryArea 'scenario' -RetryMessage "Retrying the servervm overlay for '$($Manifest.Id)' after a transient SSH/provider failure"
        }

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ClientvmRelative)) {
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the clientvm overlay for '$($Manifest.Id)'"
            Invoke-VagrantCommand -ArgumentList @('provision', 'clientvm', '--provision-with', 'scenario-client', '--no-color') -FailureMessage "Failed to apply client scenario overlay for '$($Manifest.Id)'." -RetryArea 'scenario' -RetryMessage "Retrying the clientvm overlay for '$($Manifest.Id)' after a transient SSH/provider failure" -RetryCount 3 -RetryDelaySeconds 10
        }
    }
    finally {
        Pop-Location
    }
}

function Test-GuestBaselineReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if (-not (Test-Path (Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\id"))) {
        return $false
    }

    return (Test-BaseSnapshot -MachineName $MachineName -ProjectRoot $ProjectRoot)
}

function Repair-BaselineSnapshotIfNeeded {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $machineToCheck = @('clientvm')
    if ($Manifest.Flags.RequiresServervm) {
        $machineToCheck = @('servervm', 'clientvm')
    }

    $missingBaseline = @()
    foreach ($machine in $machineToCheck) {
        if (-not (Test-GuestBaselineReady -MachineName $machine -ProjectRoot $ProjectRoot)) {
            $missingBaseline += $machine
        }
    }

    if ($missingBaseline.Count -eq 0) {
        return $false
    }

    Start-BaselineSession -ProjectRoot $ProjectRoot | Out-Null
    Invoke-BaseSnapshotRestore -ProjectRoot $ProjectRoot

    foreach ($machine in $machineToCheck) {
        if (-not (Test-GuestBaselineReady -MachineName $machine -ProjectRoot $ProjectRoot)) {
            throw "The restored baseline snapshot is incomplete on $machine. Run .\RHCSA.ps1 baseline up and verify the guest provisioning logs."
        }
    }

    return $true
}

function Invoke-LabHypervisorLockCleanup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([int])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Clean stale Vagrant and VirtualBox processes for this lab')) {
        return 0
    }

    $machineIds = @(
        Get-OptionalVagrantMachineId -MachineName 'servervm' -ProjectRoot $ProjectRoot
        Get-OptionalVagrantMachineId -MachineName 'clientvm' -ProjectRoot $ProjectRoot
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $killed = 0

    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        $name = [string]$process.Name
        $commandLine = [string]$process.CommandLine
        $kill = $false

        if ($name -in @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxSVC.exe')) {
            $kill = $true
        }
        elseif ($name -in @('VBoxHeadless.exe', 'VirtualBoxVM.exe')) {
            foreach ($machineId in $machineIds) {
                if ($commandLine -and $commandLine -like "*$machineId*") {
                    $kill = $true
                    break
                }
            }
        }

        if ($kill) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
            $killed++
        }
    }

    Start-Sleep -Seconds 2
    return $killed
}

function Invoke-ClientRecoveryConsole {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath

    Push-Location $ProjectRoot
    try {
        Write-WorkflowStatus -Area 'scenario' -Message 'Opening the clientvm recovery console'
        Invoke-ExternalCommand -FilePath (Get-VagrantPath) -ArgumentList @('halt', 'clientvm', '-f') -FailureMessage 'Failed to stop clientvm before starting recovery console.' -IgnoreExitCode
        $clientId = Get-VagrantMachineId -MachineName 'clientvm' -ProjectRoot $ProjectRoot
        Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $clientId, '--type', 'gui') -FailureMessage 'Failed to start clientvm in GUI mode for password recovery.'
    }
    finally {
        Pop-Location
    }
}

function Start-BaselineSession {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$NoProvision,
        [switch]$NormalStart,
        [switch]$HeadlessClient,
        [switch]$RealisticMode,
        [switch]$SkipEnvironmentRecovery,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $notices = @()
    if ($HeadlessClient) {
        $notices += 'HeadlessClient is deprecated. Use .\RHCSA.ps1 scenario start for password recovery scenarios.'
    }

    if ($RealisticMode) {
        $notices += 'RealisticMode is deprecated. Use .\RHCSA.ps1 scenario start for password recovery scenarios.'
    }

    if ($NormalStart) {
        $notices += 'NormalStart is now the default baseline behavior.'
    }

    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Start baseline Vagrant environment')) {
        return [PSCustomObject]@{
            Skipped = $true
            Notices = $notices
            CreatedBaseSnapshot = $false
            SnapshotReady = $false
        }
    }

    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null

    try {
        Push-Location $ProjectRoot
        try {
            if ($NoProvision) {
                Write-WorkflowStatus -Area 'baseline' -Message 'Starting servervm without guest provisioning'
                Invoke-VagrantCommand -ArgumentList @('up', 'servervm', '--no-provision', '--no-color') -FailureMessage "'vagrant up servervm --no-provision' failed." -RetryArea 'baseline' -RetryMessage 'Retrying servervm startup after a transient SSH/provider failure'
                Write-WorkflowStatus -Area 'baseline' -Message 'Starting clientvm without guest provisioning'
                Invoke-VagrantCommand -ArgumentList @('up', 'clientvm', '--no-provision', '--no-color') -FailureMessage "'vagrant up clientvm --no-provision' failed." -RetryArea 'baseline' -RetryMessage 'Retrying clientvm startup after a transient SSH/provider failure'
            }
            else {
                Write-WorkflowStatus -Area 'baseline' -Message 'Starting and provisioning servervm'
                Invoke-VagrantCommand -ArgumentList @('up', 'servervm', '--provision', '--no-color') -FailureMessage "'vagrant up servervm --provision' failed." -RetryArea 'baseline' -RetryMessage 'Retrying servervm provisioning after a transient SSH/provider failure'
                Write-WorkflowStatus -Area 'baseline' -Message 'Starting and provisioning clientvm'
                Invoke-VagrantCommand -ArgumentList @('up', 'clientvm', '--provision', '--no-color') -FailureMessage "'vagrant up clientvm --provision' failed." -RetryArea 'baseline' -RetryMessage 'Retrying clientvm provisioning after a transient SSH/provider failure'
            }
        }
        finally {
            Pop-Location
        }
    }
    catch {
        $message = $_.ToString()
        if (-not $SkipEnvironmentRecovery -and $message -match 'E_ACCESSDENIED|object functionality is limited|another process is already executing an action on the machine|Vagrant locks each machine') {
            $notices += 'Detected a stale VirtualBox machine lock. Rebuilding the Vagrant environment and retrying.'
            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
            Remove-LabEnvironment -PreserveState -ProjectRoot $ProjectRoot | Out-Null
            $recoveryResult = Start-BaselineSession `
                -NoProvision:$NoProvision `
                -NormalStart:$NormalStart `
                -HeadlessClient:$HeadlessClient `
                -RealisticMode:$RealisticMode `
                -SkipEnvironmentRecovery `
                -ProjectRoot $ProjectRoot
            $recoveryResult.Notices = @($notices + @($recoveryResult.Notices))
            return $recoveryResult
        }

        throw
    }

    $createdBaseSnapshot = $false
    $snapshotReady = $false
    if ($NoProvision) {
        $snapshotReady = (Test-BaseSnapshot -MachineName 'servervm' -ProjectRoot $ProjectRoot) -and
                         (Test-BaseSnapshot -MachineName 'clientvm' -ProjectRoot $ProjectRoot)
        if (-not $snapshotReady) {
            $notices += "Baseline VMs are running, but 'base-clean' snapshots were not created because -NoProvision was used."
        }
    }
    else {
        $createdBaseSnapshot = Invoke-BaseSnapshotInitialization -ProjectRoot $ProjectRoot -ForceRefresh
        $snapshotReady = $true
    }

    return [PSCustomObject]@{
        Skipped = $false
        Notices = $notices
        CreatedBaseSnapshot = $createdBaseSnapshot
        SnapshotReady = $snapshotReady
    }
}

function Start-ScenarioRun {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioId,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Lab', 'Exam')]
        [string]$Mode,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $modeLower = $Mode.ToLowerInvariant()
    $manifest = Get-ScenarioManifest -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot
    if ($modeLower -notin $manifest.SupportedModes) {
        throw "Scenario '$ScenarioId' does not support mode '$modeLower'. Supported modes: $($manifest.SupportedModes -join ', ')."
    }

    if (-not $PSCmdlet.ShouldProcess($ScenarioId, "Start scenario run in $modeLower mode")) {
        return $null
    }

    Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null

    $needsBaselineBootstrap = $false
    foreach ($machine in @('servervm', 'clientvm')) {
        if (-not (Test-Path (Join-Path $ProjectRoot ".vagrant\machines\$machine\virtualbox\id"))) {
            $needsBaselineBootstrap = $true
        }
    }

    if (-not $needsBaselineBootstrap) {
        foreach ($machine in @('servervm', 'clientvm')) {
            if (-not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
                $needsBaselineBootstrap = $true
            }
        }
    }

    $baselineResult = $null
    $restoreMethod = 'snapshot'
    if ($needsBaselineBootstrap) {
        Write-WorkflowStatus -Area 'scenario' -Message 'Baseline snapshots are missing; rebuilding the clean baseline first'
        $baselineResult = Start-BaselineSession -NormalStart -ProjectRoot $ProjectRoot
    }

    foreach ($machine in @('servervm', 'clientvm')) {
        if (-not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
            throw "Missing 'base-clean' snapshot for $machine. Recreate the baseline with .\RHCSA.ps1 baseline up and try again."
        }
    }

    $startedAt = Get-Date
    $endsAt = $startedAt.AddMinutes($manifest.TimeLimitMinutes)
    $runArtifact = Export-RunArtifact -Manifest $manifest -Mode $modeLower -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot
    try {
        Export-ActiveRunState -Manifest $manifest -Mode $modeLower -RunArtifact $runArtifact -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot | Out-Null

        try {
            Invoke-BaseSnapshotRestore -ProjectRoot $ProjectRoot
        }
        catch {
            $restoreMethod = 'baseline-rebuild'
            $baselineResult = Start-BaselineSession -ProjectRoot $ProjectRoot
        }

        $null = Repair-BaselineSnapshotIfNeeded -Manifest $manifest -ProjectRoot $ProjectRoot
        Invoke-ScenarioProvisioning -Manifest $manifest -ProjectRoot $ProjectRoot

        if ($manifest.Flags.PasswordRecovery) {
            Invoke-ClientRecoveryConsole -ProjectRoot $ProjectRoot
        }
    }
    catch {
        Clear-ActiveRunState -ProjectRoot $ProjectRoot
        throw
    }

    return [PSCustomObject]@{
        Manifest = $manifest
        Mode = $modeLower
        RunArtifact = $runArtifact
        StartedAt = $startedAt
        EndsAt = $endsAt
        BaselineResult = $baselineResult
        RestoreMethod = $restoreMethod
    }
}

function Get-ScenarioStatus {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $activeRun = Get-ActiveRunState -ProjectRoot $ProjectRoot
    if ($null -eq $activeRun) {
        return $null
    }

    return [PSCustomObject]@{
        ScenarioId = [string]$activeRun.scenario.id
        Category = [string]$activeRun.scenario.category
        Title = [string]$activeRun.scenario.title
        Mode = [string]$activeRun.mode
        ObjectiveTags = @($activeRun.scenario.objective_tags)
        RunId = [string]$activeRun.run_id
        StartedAt = [string]$activeRun.started_at
        EndsAt = [string]$activeRun.ends_at
        ArtifactRoot = [string]$activeRun.artifact_root
        RunBrief = [string]$activeRun.generated_artifacts.run_brief
        LabTasksDoc = [string]$activeRun.scenario.docs.lab_tasks
        LabSolutionDoc = [string]$activeRun.scenario.docs.lab_solution
        ExamTasksDoc = [string]$activeRun.scenario.docs.exam_tasks
        ExamSolutionDoc = [string]$activeRun.scenario.docs.exam_solution
    }
}

function Reset-ScenarioRun {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $activeRun = Get-ActiveRunState -ProjectRoot $ProjectRoot
    if ($null -eq $activeRun) {
        throw 'No active run found. Start a scenario first with .\RHCSA.ps1 scenario start.'
    }

    if (-not $PSCmdlet.ShouldProcess([string]$activeRun.scenario.id, 'Reset scenario run')) {
        return $null
    }

    $mode = ([string]$activeRun.mode).Substring(0, 1).ToUpperInvariant() + ([string]$activeRun.mode).Substring(1)
    return Start-ScenarioRun -ScenarioId $activeRun.scenario.id -Mode $mode -ProjectRoot $ProjectRoot
}

function Get-VBoxMachineFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('list', 'systemproperties')
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return $null
    }

    $line = $result.StdOut | Where-Object { $_ -match '^Default machine folder:' } | Select-Object -First 1
    if (-not $line) {
        return $null
    }

    return ($line -replace '^Default machine folder:\s*', '').Trim()
}

function Get-VBoxVmCatalog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('list', 'vms')
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return @()
    }

    $items = @()
    foreach ($line in $result.StdOut) {
        if ($line -match '^"(.+)"\s+\{([0-9a-fA-F-]+)\}$') {
            $items += [PSCustomObject]@{
                Name = $matches[1]
                Id = $matches[2]
            }
        }
    }

    return $items
}

function Test-VBoxVmRegistration {
    param(
        [object[]]$RegisteredVm = @(),
        [Parameter(Mandatory = $true)]
        [string]$VmId
    )

    return $null -ne ($RegisteredVm | Where-Object { $_.Id -eq $VmId } | Select-Object -First 1)
}

function Get-LabVBoxVmCandidate {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $projectName = Split-Path -Leaf $ProjectRoot
    $registeredVm = @(Get-VBoxVmCatalog -VBoxManagePath $VBoxManagePath)
    $candidate = @()

    foreach ($machineName in @('servervm', 'clientvm')) {
        $vmId = Get-OptionalVagrantMachineId -MachineName $machineName -ProjectRoot $ProjectRoot
        if ($vmId) {
            $match = $registeredVm | Where-Object { $_.Id -eq $vmId } | Select-Object -First 1
            if ($null -ne $match) {
                $candidate += $match
            }
        }
    }

    $namePattern = '^' + [regex]::Escape($projectName) + '_(servervm|clientvm)_'
    $legacyPattern = '^rhcsa-ex200-(servervm|clientvm)'

    foreach ($machine in $registeredVm) {
        if ($machine.Name -match $namePattern -or $machine.Name -match $legacyPattern) {
            if (-not ($candidate | Where-Object { $_.Id -eq $machine.Id })) {
                $candidate += $machine
            }
        }
    }

    return @($candidate | Sort-Object Id -Unique)
}

function Invoke-VBoxVmRemoval {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath,
        [Parameter(Mandatory = $true)]
        [string]$VmId
    )

    Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('controlvm', $VmId, 'poweroff') -FailureMessage "Failed to power off VM '$VmId' before unregister." -IgnoreExitCode -SuppressOutput
    Start-Sleep -Seconds 2

    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $exitCode = Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('unregistervm', $VmId, '--delete') -FailureMessage "Failed to unregister VM '$VmId'." -IgnoreExitCode -PassThruExitCode -SuppressOutput
        if ($exitCode -eq 0) {
            return
        }

        $exitCode = Invoke-ExternalCommand -FilePath $VBoxManagePath -ArgumentList @('unregistervm', $VmId) -FailureMessage "Failed to unregister VM '$VmId' without media deletion." -IgnoreExitCode -PassThruExitCode -SuppressOutput
        if ($exitCode -eq 0) {
            return
        }

        Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 10))
    }
}

function Get-VBoxHardDiskCatalog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath
    )

    $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @('list', 'hdds')
    if ($result.ExitCode -ne 0 -or -not $result.StdOut) {
        return @()
    }

    $items = @()
    $uuid = $null
    $location = $null

    foreach ($line in $result.StdOut) {
        if ($line -match '^UUID:\s+(.+)$') {
            if ($uuid -and $location) {
                $items += [PSCustomObject]@{
                    UUID = $uuid
                    Location = $location
                }
            }

            $uuid = $matches[1].Trim()
            $location = $null
            continue
        }

        if ($line -match '^Location:\s+(.+)$') {
            $location = $matches[1].Trim()
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($uuid -and $location) {
                $items += [PSCustomObject]@{
                    UUID = $uuid
                    Location = $location
                }
            }

            $uuid = $null
            $location = $null
        }
    }

    if ($uuid -and $location) {
        $items += [PSCustomObject]@{
            UUID = $uuid
            Location = $location
        }
    }

    return $items
}

function Invoke-VBoxHardDiskCleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VBoxManagePath,
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        return
    }

    $folderFull = (Resolve-Path -LiteralPath $FolderPath).Path
    $folderNorm = $folderFull.Replace('/', '\').ToLowerInvariant().TrimEnd('\') + '\'

    $hardDiskCatalog = Get-VBoxHardDiskCatalog -VBoxManagePath $VBoxManagePath
    foreach ($hardDisk in $hardDiskCatalog) {
        $locationNorm = $hardDisk.Location.Replace('/', '\').ToLowerInvariant()
        if ($locationNorm.StartsWith($folderNorm)) {
            & $VBoxManagePath closemedium disk $hardDisk.UUID --delete 1>$null 2>$null
        }
    }
}

function Invoke-OrphanVmFolderCleanup {
    param(
        [string]$VBoxMachineFolder,
        [string]$ProjectName
    )

    if (-not $VBoxMachineFolder -or -not (Test-Path -LiteralPath $VBoxMachineFolder)) {
        return
    }

    $patterns = @(
        "${ProjectName}_servervm_*",
        "${ProjectName}_clientvm_*",
        'rhcsa-ex200-servervm*',
        'rhcsa-ex200-clientvm*'
    )

    foreach ($pattern in $patterns) {
        Get-ChildItem -LiteralPath $VBoxMachineFolder -Directory -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
    }
}

function Remove-LabEnvironment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$PreserveState,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $notes = @()
    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Destroy RHCSA lab environment and cleanup local state')) {
        return [PSCustomObject]@{
            Skipped = $true
            Notes = $notes
            RemovedPaths = @()
        }
    }

    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null

    $projectName = Split-Path -Leaf $ProjectRoot
    $vboxManage = Get-OptionalVBoxManagePath
    $vboxMachineFolder = if ($vboxManage) { Get-VBoxMachineFolder -VBoxManagePath $vboxManage } else { $null }

    $serverId = Get-OptionalVagrantMachineId -MachineName 'servervm' -ProjectRoot $ProjectRoot
    $clientId = Get-OptionalVagrantMachineId -MachineName 'clientvm' -ProjectRoot $ProjectRoot
    $labDisksDir = Join-Path $ProjectRoot '.lab-disks'
    $legacyDisksDir = Join-Path $ProjectRoot '.vagrant\disks'
    $removedPaths = @()

    Push-Location $ProjectRoot
    try {
        if (Test-Path '.\Vagrantfile') {
            try {
                $exitCode = Invoke-ExternalCommand `
                    -FilePath (Get-VagrantPath) `
                    -ArgumentList @('destroy', '-f') `
                    -FailureMessage 'vagrant destroy failed.' `
                    -IgnoreExitCode `
                    -PassThruExitCode `
                    -SuppressOutput
                if ($exitCode -ne 0) {
                    $notes += "vagrant destroy returned exit code $exitCode. Continuing cleanup."
                }
            }
            catch {
                $notes += 'vagrant destroy failed. Continuing cleanup.'
            }
        }

        if ($vboxManage) {
            foreach ($candidate in (Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)) {
                Invoke-VBoxVmRemoval -VBoxManagePath $vboxManage -VmId $candidate.Id
            }

            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null

            foreach ($candidate in (Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)) {
                Invoke-VBoxVmRemoval -VBoxManagePath $vboxManage -VmId $candidate.Id
            }

            Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $labDisksDir
            Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $legacyDisksDir
            Invoke-OrphanVmFolderCleanup -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
        }

        $paths = @(
            '.\.vagrant',
            '.\.lab-disks',
            '.\output',
            '.\builds',
            '.\packer_cache'
        )

        if (-not $PreserveState) {
            $paths += '.\.lab-state'
        }

        foreach ($path in $paths) {
            if (Test-Path $path) {
                Remove-Item -LiteralPath $path -Recurse -Force
                $removedPaths += $path
            }
        }

        Get-ChildItem -Path . -Filter '*.vdi' -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force
                $removedPaths += $_.FullName
            }
    }
    finally {
        Pop-Location
    }

    return [PSCustomObject]@{
        Skipped = $false
        Notes = $notes
        RemovedPaths = $removedPaths
    }
}
