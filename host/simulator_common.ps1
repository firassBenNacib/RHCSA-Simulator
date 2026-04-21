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
    'software-management',
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

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    $rootWithSeparator = $fullRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar

    if (-not $fullPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path '$fullPath' is outside project root '$fullRoot'."
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
        [AllowNull()]
        [object]$Value = $null,
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

    return ,$items
}

function ConvertTo-ScenarioTrack {
    param(
        [AllowEmptyString()]
        [string]$Track
    )

    $value = ([string]$Track).Trim().ToLowerInvariant() -replace '[-_]', ''
    switch ($value) {
        { $_ -in @('', 'all') } { return 'all' }
        { $_ -in @('9', 'rhel9', 'rhcsa9', 'ex2009') } { return 'rhcsa9' }
        { $_ -in @('10', 'rhel10', 'rhcsa10', 'ex20010') } { return 'rhcsa10' }
        default { throw "Unsupported scenario track '$Track'. Use RHCSA9, RHCSA10, or All." }
    }
}

function Get-ScenarioTrackArray {
    param(
        [AllowNull()]
        [object]$Value = $null,
        [string]$Label = 'tracks'
    )

    $raw = @(Get-StringArray -Value $Value -Label $Label -AllowEmpty)
    if ($raw.Count -eq 0) {
        return ,@('rhcsa9')
    }

    $tracks = @()
    foreach ($item in $raw) {
        $track = ConvertTo-ScenarioTrack -Track $item
        if ($track -ne 'all' -and $track -notin $tracks) {
            $tracks += $track
        }
    }

    if ($tracks.Count -eq 0) {
        return ,@('rhcsa9')
    }

    return ,$tracks
}

function Test-ScenarioTrackMatch {
    param(
        [string[]]$ScenarioTracks = @('rhcsa9'),
        [string]$Track = 'rhcsa9'
    )

    $normalized = ConvertTo-ScenarioTrack -Track $Track
    if ($normalized -eq 'all') {
        return $true
    }

    return $normalized -in @($ScenarioTracks)
}

function Get-IntegerArray {
    param(
        [AllowNull()]
        [object]$Value = $null,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [switch]$AllowEmpty
    )

    $items = @()
    foreach ($item in @($Value)) {
        if ($null -eq $item -or [string]::IsNullOrWhiteSpace([string]$item)) {
            continue
        }

        $number = [int]$item
        if ($number -le 0) {
            throw "$Label entries must be positive integers."
        }

        $items += $number
    }

    if (-not $AllowEmpty -and $items.Count -eq 0) {
        throw "$Label must contain at least one entry."
    }

    return ,$items
}

function Get-StringMatrix {
    param(
        [AllowNull()]
        [object]$Value = $null,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [switch]$AllowEmpty
    )

    $rows = @()
    $rowIndex = 0
    $sourceRows = @($Value)
    $hasNestedRows = $false

    foreach ($row in $sourceRows) {
        if ($null -eq $row) {
            continue
        }

        if ($row -isnot [string] -and $row -is [System.Collections.IEnumerable]) {
            $hasNestedRows = $true
            break
        }
    }

    if (-not $hasNestedRows) {
        $sourceRows = ,$sourceRows
    }

    foreach ($row in $sourceRows) {
        $rowIndex++
        $rows += ,(Get-StringArray -Value $row -Label ("{0}[{1}]" -f $Label, $rowIndex) -AllowEmpty:$AllowEmpty)
    }

    if (-not $AllowEmpty -and $rows.Count -eq 0) {
        throw "$Label must contain at least one entry."
    }

    return ,$rows
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

    $tracks = Get-ScenarioTrackArray -Value (Get-OptionalPropertyValue -Object $raw -Name 'tracks') -Label "Scenario '$id' tracks"
    $rhelMajorRaw = Get-OptionalPropertyValue -Object $raw -Name 'rhel_major'
    $rhelMajor = if ($null -eq $rhelMajorRaw -or [string]::IsNullOrWhiteSpace([string]$rhelMajorRaw)) { 9 } else { [int]$rhelMajorRaw }
    if ($rhelMajor -notin @(9, 10)) {
        throw "Scenario '$id' rhel_major must be 9 or 10."
    }

    $flags = Get-RequiredProperty -Object $raw -Name 'flags'
    $passwordRecovery = [bool](Get-RequiredProperty -Object $flags -Name 'password_recovery' -AllowZero)
    $requiresServer = [bool](Get-RequiredProperty -Object $flags -Name 'requires_server' -AllowZero)

    $vmScriptsRaw = Get-OptionalPropertyValue -Object $raw -Name 'vm_scripts'
    if ($null -eq $vmScriptsRaw) {
        $vmScriptsRaw = [PSCustomObject]@{}
    }

    $serverScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'server'
    if ($null -eq $serverScriptValue) {
        $serverScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'servervm'
    }
    $clientScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'client'
    if ($null -eq $clientScriptValue) {
        $clientScriptValue = Get-OptionalPropertyValue -Object $vmScriptsRaw -Name 'clientvm'
    }

    $serverScript = Resolve-ScenarioScriptPath -ScenarioRoot $scenarioRoot -RelativePath ([string]$serverScriptValue) -Label 'vm_scripts.server' -ProjectRoot $ProjectRoot
    $clientScript = Resolve-ScenarioScriptPath -ScenarioRoot $scenarioRoot -RelativePath ([string]$clientScriptValue) -Label 'vm_scripts.client' -ProjectRoot $ProjectRoot
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
    $labTaskTitles = @()
    $labTaskPoints = @()
    $labSolutionCommands = @()
    $labHints = @()
    $labChecks = @()
    $labSolutionOutline = @()
    if ($null -ne $labContent) {
        $labTasks = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'tasks') -Label "Scenario '$id' content.lab.tasks"
        $labTaskTitles = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'task_titles') -Label "Scenario '$id' content.lab.task_titles"
        $labTaskPoints = Get-IntegerArray -Value (Get-RequiredProperty -Object $labContent -Name 'task_points') -Label "Scenario '$id' content.lab.task_points"
        $labSolutionCommands = Get-StringMatrix -Value (Get-RequiredProperty -Object $labContent -Name 'solution_commands') -Label "Scenario '$id' content.lab.solution_commands"
        $labHints = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'hints' -AllowZero) -Label "Scenario '$id' content.lab.hints" -AllowEmpty
        $labChecks = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'checks' -AllowZero) -Label "Scenario '$id' content.lab.checks" -AllowEmpty
        $labSolutionOutline = Get-StringArray -Value (Get-RequiredProperty -Object $labContent -Name 'solution_outline' -AllowZero) -Label "Scenario '$id' content.lab.solution_outline" -AllowEmpty

        if ($labTaskTitles.Count -ne $labTasks.Count) {
            throw "Scenario '$id' content.lab.task_titles must match the task count."
        }

        if ($labTaskPoints.Count -ne $labTasks.Count) {
            throw "Scenario '$id' content.lab.task_points must match the task count."
        }

        if ($labSolutionCommands.Count -ne $labTasks.Count) {
            throw "Scenario '$id' content.lab.solution_commands must match the task count."
        }
    }

    $examTasks = @()
    $examTaskTitles = @()
    $examTaskPoints = @()
    $examSolutionCommands = @()
    if ($null -ne $examContent) {
        $examTasks = Get-StringArray -Value (Get-RequiredProperty -Object $examContent -Name 'tasks') -Label "Scenario '$id' content.exam.tasks"
        $examTaskTitles = Get-StringArray -Value (Get-RequiredProperty -Object $examContent -Name 'task_titles') -Label "Scenario '$id' content.exam.task_titles"
        $examTaskPoints = Get-IntegerArray -Value (Get-RequiredProperty -Object $examContent -Name 'task_points') -Label "Scenario '$id' content.exam.task_points"
        $examSolutionCommands = Get-StringMatrix -Value (Get-RequiredProperty -Object $examContent -Name 'solution_commands') -Label "Scenario '$id' content.exam.solution_commands"

        if ($examTaskTitles.Count -ne $examTasks.Count) {
            throw "Scenario '$id' content.exam.task_titles must match the task count."
        }

        if ($examTaskPoints.Count -ne $examTasks.Count) {
            throw "Scenario '$id' content.exam.task_points must match the task count."
        }

        if ($examSolutionCommands.Count -ne $examTasks.Count) {
            throw "Scenario '$id' content.exam.solution_commands must match the task count."
        }

        if ((($examTaskPoints | Measure-Object -Sum).Sum) -ne 100) {
            throw "Scenario '$id' content.exam.task_points must sum to 100."
        }
    }

    return [PSCustomObject]@{
        Id = $id
        Category = $scenarioCategory
        Title = $title
        Description = $description
        ObjectiveTags = $objectiveTags
        SupportedModes = $supportedModes
        TimeLimitMinutes = $timeLimit
        Tracks = $tracks
        RHELMajor = $rhelMajor
        ScenarioRoot = $scenarioRoot
        RelativeScenarioRoot = $relativeScenarioRoot
        ManifestPath = $manifestFullPath
        RelativeManifestPath = (Get-ProjectRelativePath -Path $manifestFullPath -ProjectRoot $ProjectRoot)
        VmScripts = [PSCustomObject]@{
            Server = $serverScript.FullPath
            ServerRelative = $serverScript.RelativePath
            Client = $clientScript.FullPath
            ClientRelative = $clientScript.RelativePath
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
            RequiresServer = $requiresServer
        }
        Content = [PSCustomObject]@{
            Lab = [PSCustomObject]@{
                Tasks = $labTasks
                TaskTitles = $labTaskTitles
                TaskPoints = $labTaskPoints
                SolutionCommands = $labSolutionCommands
                Hints = $labHints
                Checks = $labChecks
                SolutionOutline = $labSolutionOutline
            }
            Exam = [PSCustomObject]@{
                Tasks = $examTasks
                TaskTitles = $examTaskTitles
                TaskPoints = $examTaskPoints
                SolutionCommands = $examSolutionCommands
            }
        }
    }
}

function Get-ScenarioCatalog {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Track = 'rhcsa9'
    )

    $scenariosRoot = Join-Path $ProjectRoot 'scenarios'
    if (-not (Test-Path $scenariosRoot -PathType Container)) {
        return @()
    }

    $manifestFiles = @(Get-ChildItem -Path $scenariosRoot -Filter 'scenario.json' -File -Recurse | Sort-Object FullName)
    $catalog = foreach ($file in $manifestFiles) {
        ConvertTo-ScenarioManifest -ManifestPath $file.FullName -ProjectRoot $ProjectRoot
    }

    return @($catalog | Where-Object { Test-ScenarioTrackMatch -ScenarioTracks @($_.Tracks) -Track $Track } | Sort-Object Category, Id)
}

function Get-ScenarioManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioId,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Track = 'all'
    )

    $matchingManifest = @(Get-ScenarioCatalog -ProjectRoot $ProjectRoot -Track $Track | Where-Object { $_.Id -eq $ScenarioId })
    if ($matchingManifest.Count -eq 0) {
        throw "Scenario '$ScenarioId' not found."
    }

    if ($matchingManifest.Count -gt 1) {
        throw "Scenario id '$ScenarioId' is duplicated in the scenario catalog."
    }

    return $matchingManifest[0]
}

function ConvertTo-ExerciseCheckEntry {
param(
[Parameter(Mandatory = $true)]
[string]$Command,
[Parameter(Mandatory = $true)]
[int]$Index
)

$trimmedCommand = $Command.Trim()
$target = 'client'
$effectiveCommand = $trimmedCommand

if ($trimmedCommand -match '^\s*ssh\s+(?<host>\S*server\S*)\s+(?<remote>.+?)\s*$') {
$remoteCommand = [string]$matches['remote']
$remoteCommand = ($remoteCommand -replace '^\s*sudo\s+', '').Trim()
if (-not [string]::IsNullOrWhiteSpace($remoteCommand)) {
$target = 'server'
$effectiveCommand = $trimmedCommand
$effectiveCommand = $effectiveCommand -replace '(?i)(^|&&\s*)ssh\s+\S*server\S*\s+(?:sudo\s+)?', '$1'
$effectiveCommand = $effectiveCommand.Trim()
}
}
elseif ($trimmedCommand -match '^\s*#\s*server\s+') {
$target = 'server'
$effectiveCommand = $trimmedCommand -replace '^\s*#\s*server\s+', ''
$effectiveCommand = $effectiveCommand.Trim()
}

return [PSCustomObject]@{
Index = $Index
Target = $target
OriginalCommand = $trimmedCommand
Command = $effectiveCommand
}
}

function Format-ScenarioText {
    param(
        [AllowEmptyString()]
        [string]$Text
    )

    if ($null -eq $Text) {
        return ''
    }

    $normalized = ($Text -replace "`r`n", "`n").Trim("`n")
    $lines = @($normalized -split "`n" | ForEach-Object { $_.TrimEnd() })
    if ($lines.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace($lines[0])) {
        if ($lines[0][-1] -notin @('.', ':', '!', '?')) {
            $lines[0] += '.'
        }
    }

    return (($lines -join "`n").Trim())
}

function Get-ScenarioLabHintsMarkdown {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest
    )

    $lines = @(
        "# $($Manifest.Title) Hints",
        ''
    )

    $hints = @($Manifest.Content.Lab.Hints)
    if ($hints.Count -eq 0) {
        $lines += '- No hints are defined for this lab.'
        return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
    }

    foreach ($hint in $hints) {
        $text = Format-ScenarioText -Text ([string]$hint)
        $text = $text.TrimEnd('.')
        $lines += "- $text."
    }

    return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function Get-ScenarioLabCheckScript {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Checks
    )

    $lines = @()

    if ($Checks.Count -eq 0) {
        $lines += '# No automated checks are defined for this lab.'
        $lines += 'echo "No automated checks are defined for this lab."'
        return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
    }

    foreach ($check in $Checks) {
        $lines += ('# Check {0:d2} [{1}]' -f [int]$check.Index, [string]$check.Target)
        if ([string]$check.Command -ne [string]$check.OriginalCommand) {
            $lines += "# Source: $([string]$check.OriginalCommand)"
        }
        $lines += [string]$check.Command
        $lines += ''
    }

    return (($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}

function Get-ScenarioSourceHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [string](Get-FileHash -Path $Path -Algorithm SHA256).Hash
}

function Initialize-LabExerciseCache {
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    if ([string]$Manifest.Category -ne 'labs') {
        throw "Scenario '$($Manifest.Id)' is not a lab exercise."
    }

    Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
    $runtimeRoot = Get-GeneratedLabRuntimeRoot -ScenarioId $Manifest.Id -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $runtimeRoot)) {
        New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
    }

    $promptPath = Join-Path $runtimeRoot 'prompt.md'
    $hintPath = Join-Path $runtimeRoot 'hint.md'
    $checkPath = Join-Path $runtimeRoot 'check.sh'
    $solutionPath = Join-Path $runtimeRoot 'solution.md'
    $metadataPath = Join-Path $runtimeRoot 'exercise.json'
    $sourceHash = Get-ScenarioSourceHash -Path $Manifest.ManifestPath

    $checks = @()
    $checkIndex = 0
    foreach ($checkCommand in @($Manifest.Content.Lab.Checks)) {
        $checkIndex++
        $checks += ConvertTo-ExerciseCheckEntry -Command ([string]$checkCommand) -Index $checkIndex
    }

    $expectedCheckMetadata = @(
        foreach ($check in $checks) {
            [ordered]@{
                index = [int]$check.Index
                target = [string]$check.Target
                original_command = [string]$check.OriginalCommand
                command = [string]$check.Command
            }
        }
    )

    $existingMetadata = $null
    if (Test-Path -LiteralPath $metadataPath -PathType Leaf) {
        try {
            $rawMetadata = Get-Content -LiteralPath $metadataPath -Raw
            if ($rawMetadata.Length -gt 0 -and [int][char]$rawMetadata[0] -eq 0xFEFF) {
                $rawMetadata = $rawMetadata.Substring(1)
            }
            $existingMetadata = $rawMetadata | ConvertFrom-Json
        }
        catch {
            $existingMetadata = $null
        }
    }

    $pathsReady = @($promptPath, $hintPath, $checkPath, $solutionPath) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
    $checksReady = $false
    if ($null -ne $existingMetadata) {
        $expectedChecksJson = ($expectedCheckMetadata | ConvertTo-Json -Depth 8 -Compress)
        $existingChecksJson = (@($existingMetadata.checks) | ConvertTo-Json -Depth 8 -Compress)
        $checksReady = $expectedChecksJson -eq $existingChecksJson
    }
    $cacheFresh = $null -ne $existingMetadata -and
        [string](Get-OptionalPropertyValue -Object $existingMetadata -Name 'source_hash') -eq $sourceHash -and
        $pathsReady.Count -eq 4 -and
        $checksReady

    if (-not $cacheFresh) {
        Copy-Item -LiteralPath $Manifest.Docs.LabTasks -Destination $promptPath -Force
        Copy-Item -LiteralPath $Manifest.Docs.LabSolution -Destination $solutionPath -Force

        Set-Utf8NoBomFile -Path $hintPath -Content (Get-ScenarioLabHintsMarkdown -Manifest $Manifest)
        Set-Utf8NoBomFile -Path $checkPath -Content (Get-ScenarioLabCheckScript -Checks $checks)

        $metadata = [ordered]@{
            id = $Manifest.Id
            title = $Manifest.Title
            description = $Manifest.Description
            time_limit_minutes = [int]$Manifest.TimeLimitMinutes
            objective_tags = @($Manifest.ObjectiveTags)
            requires_server = [bool]$Manifest.Flags.RequiresServer
            source_manifest = $Manifest.RelativeManifestPath
            source_hash = $sourceHash
            paths = [ordered]@{
                prompt = Get-ProjectRelativePath -Path $promptPath -ProjectRoot $ProjectRoot
                hint = Get-ProjectRelativePath -Path $hintPath -ProjectRoot $ProjectRoot
                check = Get-ProjectRelativePath -Path $checkPath -ProjectRoot $ProjectRoot
                solution = Get-ProjectRelativePath -Path $solutionPath -ProjectRoot $ProjectRoot
                metadata = Get-ProjectRelativePath -Path $metadataPath -ProjectRoot $ProjectRoot
            }
            checks = $expectedCheckMetadata
        }

        Set-Utf8NoBomFile -Path $metadataPath -Content (($metadata | ConvertTo-Json -Depth 8) + [Environment]::NewLine)
        $existingMetadata = $metadata | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    }

    return $existingMetadata
}

function Get-LabExerciseDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenarioId,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $manifest = Get-ScenarioManifest -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot
    if ($manifest.Category -ne 'labs') {
        throw "Scenario '$ScenarioId' is not a lab exercise."
    }

    $metadata = Initialize-LabExerciseCache -Manifest $manifest -ProjectRoot $ProjectRoot
    $exerciseChecks = @(
        @($metadata.checks) | ForEach-Object {
            [PSCustomObject]@{
                Index = [int]$_.index
                Target = [string]$_.target
                OriginalCommand = [string]$_.original_command
                Command = [string]$_.command
            }
        }
    )

    return [PSCustomObject]@{
        Id = [string]$metadata.id
        Title = [string]$metadata.title
        Description = [string]$metadata.description
        TimeLimitMinutes = [int]$metadata.time_limit_minutes
        ObjectiveTags = @($metadata.objective_tags)
        RequiresServer = [bool]$metadata.requires_server
        SourceManifest = [string]$metadata.source_manifest
        Paths = [PSCustomObject]@{
            Prompt = [string]$metadata.paths.prompt
            Hint = [string]$metadata.paths.hint
            Check = [string]$metadata.paths.check
            Solution = [string]$metadata.paths.solution
            Metadata = [string]$metadata.paths.metadata
        }
        Checks = $exerciseChecks
    }
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

    $systems = if ($Manifest.Flags.RequiresServer) { 'client and server' } else { 'client' }
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
            objective_tags = @($Manifest.ObjectiveTags)
            supported_modes = @($Manifest.SupportedModes)
            tracks = @($Manifest.Tracks)
            rhel_major = [int]$Manifest.RHELMajor
            time_limit_minutes = $Manifest.TimeLimitMinutes
            scenario_root = $Manifest.RelativeScenarioRoot
            manifest_path = $Manifest.RelativeManifestPath
            vm_scripts = [ordered]@{
                server = $Manifest.VmScripts.ServerRelative
                client = $Manifest.VmScripts.ClientRelative
            }
            docs = [ordered]@{
                lab_tasks = $Manifest.Docs.LabTasksRelative
                lab_solution = $Manifest.Docs.LabSolutionRelative
                exam_tasks = $Manifest.Docs.ExamTasksRelative
                exam_solution = $Manifest.Docs.ExamSolutionRelative
            }
            flags = [ordered]@{
                password_recovery = $Manifest.Flags.PasswordRecovery
                requires_server = $Manifest.Flags.RequiresServer
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

    [Console]::Out.WriteLine(('{0}  {1}{2}' -f $prefix, $progressPrefix, $Message))
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
        Wait-VagrantClientQuiescence | Out-Null

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

function Invoke-VagrantMachineStep {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [switch]$Provision,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$RetryArea = 'baseline'
    )

    $upArgumentList = @('up', $MachineName, '--no-provision', '--no-color')
    $upFailureMessage = "'vagrant up $MachineName --no-provision' failed."
    $upRetryMessage = if ($Provision) {
        "Retrying $MachineName startup before provisioning after a transient SSH/provider failure"
    }
    else {
        "Retrying $MachineName startup after a transient SSH/provider failure"
    }

    try {
        Invoke-VagrantCommand -ArgumentList $upArgumentList -FailureMessage $upFailureMessage -RetryArea $RetryArea -RetryMessage $upRetryMessage
        if ($Provision) {
            Confirm-VagrantGuestProvisionReadiness `
                -MachineName $MachineName `
                -ProjectRoot $ProjectRoot `
                -Area $RetryArea `
                -MaxAttempts 12 `
                -DelaySeconds 10 `
                -RequiredSuccesses 1 `
                -StabilizationDelaySeconds 3 `
                -AllowStartupRetry
            Invoke-VagrantCommand -ArgumentList @('provision', $MachineName, '--no-color') -FailureMessage "'vagrant provision $MachineName' failed after startup." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName provisioning after a transient SSH/provider failure"
        }
        return
    }
    catch {
        $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot | Where-Object { [string]$_.Name -eq $MachineName } | Select-Object -First 1)
        if ($machineStatus.Count -eq 0) {
            throw
        }

        $stateHuman = [string]$machineStatus[0].StateHuman
        switch ($stateHuman) {
            'running' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; completing VM startup"
                Confirm-VagrantGuestProvisionReadiness `
                    -MachineName $MachineName `
                    -ProjectRoot $ProjectRoot `
                    -Area $RetryArea `
                    -MaxAttempts 12 `
                    -DelaySeconds 10 `
                    -RequiredSuccesses 1 `
                    -StabilizationDelaySeconds 3 `
                    -AllowStartupRetry
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed after partial startup recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName startup after a transient SSH/provider failure"
                if (-not $Provision) {
                    return
                }

                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName startup; resuming provisioning"
                Confirm-VagrantGuestProvisionReadiness `
                    -MachineName $MachineName `
                    -ProjectRoot $ProjectRoot `
                    -Area $RetryArea `
                    -MaxAttempts 12 `
                    -DelaySeconds 10 `
                    -RequiredSuccesses 1 `
                    -StabilizationDelaySeconds 3 `
                    -AllowStartupRetry
                Invoke-VagrantCommand -ArgumentList @('provision', $MachineName, '--no-color') -FailureMessage "'vagrant provision $MachineName' failed after partial startup recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName provisioning after a transient SSH/provider failure"
                return
            }
            'poweroff' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName import; resuming VM startup"
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName startup after a transient SSH/provider failure"
                if ($Provision) {
                    Confirm-VagrantGuestProvisionReadiness `
                        -MachineName $MachineName `
                        -ProjectRoot $ProjectRoot `
                        -Area $RetryArea `
                        -MaxAttempts 12 `
                        -DelaySeconds 10 `
                        -RequiredSuccesses 1 `
                        -StabilizationDelaySeconds 3 `
                        -AllowStartupRetry
                    Invoke-VagrantCommand -ArgumentList @('provision', $MachineName, '--no-color') -FailureMessage "'vagrant provision $MachineName' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName provisioning after a transient SSH/provider failure"
                }
                return
            }
            'saved' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName import; resuming VM startup"
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName startup after a transient SSH/provider failure"
                if ($Provision) {
                    Confirm-VagrantGuestProvisionReadiness `
                        -MachineName $MachineName `
                        -ProjectRoot $ProjectRoot `
                        -Area $RetryArea `
                        -MaxAttempts 12 `
                        -DelaySeconds 10 `
                        -RequiredSuccesses 1 `
                        -StabilizationDelaySeconds 3 `
                        -AllowStartupRetry
                    Invoke-VagrantCommand -ArgumentList @('provision', $MachineName, '--no-color') -FailureMessage "'vagrant provision $MachineName' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName provisioning after a transient SSH/provider failure"
                }
                return
            }
            'paused' {
                Write-WorkflowStatus -Area $RetryArea -Message "Recovered from a partial $MachineName import; resuming VM startup"
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName startup after a transient SSH/provider failure"
                if ($Provision) {
                    Confirm-VagrantGuestProvisionReadiness `
                        -MachineName $MachineName `
                        -ProjectRoot $ProjectRoot `
                        -Area $RetryArea `
                        -MaxAttempts 12 `
                        -DelaySeconds 10 `
                        -RequiredSuccesses 1 `
                        -StabilizationDelaySeconds 3 `
                        -AllowStartupRetry
                    Invoke-VagrantCommand -ArgumentList @('provision', $MachineName, '--no-color') -FailureMessage "'vagrant provision $MachineName' failed after partial import recovery." -RetryArea $RetryArea -RetryMessage "Retrying $MachineName provisioning after a transient SSH/provider failure"
                }
                return
            }
        }

        throw
    }
}

function Invoke-InteractiveExternalCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string[]]$ArgumentList = @(),
        [string]$FailureMessage = 'Command failed.'
    )

    & $FilePath @ArgumentList
    $exitCode = Get-NativeExitCode
    if ($exitCode -ne 0) {
        $commandText = @($FilePath) + $ArgumentList
        throw "$FailureMessage Command: $($commandText -join ' ') Exit code: $exitCode"
    }
}

function Get-VagrantMachineStatus {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vagrantPath = Get-VagrantPath

    Push-Location $ProjectRoot
    try {
        $result = Invoke-ExternalCapture -FilePath $vagrantPath -ArgumentList @('status', '--machine-readable')
    }
    finally {
        Pop-Location
    }

    if ($result.ExitCode -ne 0) {
        $fallback = @(Get-VirtualBoxMachineStatusFallback -ProjectRoot $ProjectRoot)
        if ($fallback.Count -gt 0) {
            return $fallback
        }

        Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
        throw "Failed to read local Vagrant machine status."
    }

    $statusMap = @{}
    foreach ($line in @($result.StdOut)) {
        $text = [string]$line
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $parts = $text -split ',', 4
        if ($parts.Count -ne 4) {
            continue
        }

        $machineName = [string]$parts[1]
        $eventName = [string]$parts[2]
        $eventValue = [string]$parts[3]

        if ([string]::IsNullOrWhiteSpace($machineName)) {
            continue
        }

        if (-not $statusMap.ContainsKey($machineName)) {
            $statusMap[$machineName] = [ordered]@{
                Name = $machineName
                State = 'not_created'
                StateHuman = 'not created'
                Provider = 'virtualbox'
            }
        }

        switch ($eventName) {
            'state' { $statusMap[$machineName].State = $eventValue }
            'state-human-short' { $statusMap[$machineName].StateHuman = $eventValue }
            'provider-name' { $statusMap[$machineName].Provider = $eventValue }
        }
    }

    $machineStatus = foreach ($machineName in @('server', 'client')) {
        if ($statusMap.ContainsKey($machineName)) {
            [PSCustomObject]$statusMap[$machineName]
        }
        else {
            [PSCustomObject]@{
                Name = $machineName
                State = 'not_created'
                StateHuman = 'not created'
                Provider = 'virtualbox'
            }
        }
    }

    return @($machineStatus)
}

function ConvertFrom-VirtualBoxState {
    param(
        [string]$State
    )

    $normalized = ([string]$State).Trim().ToLowerInvariant()
    switch ($normalized) {
        'running' { return [PSCustomObject]@{ State = 'running'; StateHuman = 'running' } }
        'poweroff' { return [PSCustomObject]@{ State = 'poweroff'; StateHuman = 'poweroff' } }
        'saved' { return [PSCustomObject]@{ State = 'saved'; StateHuman = 'saved' } }
        'paused' { return [PSCustomObject]@{ State = 'paused'; StateHuman = 'paused' } }
        'aborted' { return [PSCustomObject]@{ State = 'aborted'; StateHuman = 'aborted' } }
        default { return [PSCustomObject]@{ State = $normalized; StateHuman = if ([string]::IsNullOrWhiteSpace($normalized)) { 'unknown' } else { $normalized } } }
    }
}

function Get-VirtualBoxMachineStatusFallback {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-OptionalVBoxManagePath
    $fallbackStatus = @()

    foreach ($machineName in @('server', 'client')) {
        $machineId = Get-OptionalVagrantMachineId -MachineName $machineName -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($machineId)) {
            $fallbackStatus += [PSCustomObject]@{
                Name = $machineName
                State = 'not_created'
                StateHuman = 'not created'
                Provider = 'virtualbox'
            }
            continue
        }

        if (-not $vboxManage) {
            $fallbackStatus += [PSCustomObject]@{
                Name = $machineName
                State = 'unknown'
                StateHuman = 'unknown'
                Provider = 'virtualbox'
            }
            continue
        }

        $result = Invoke-ExternalCapture -FilePath $vboxManage -ArgumentList @('showvminfo', $machineId, '--machinereadable')
        if ($result.ExitCode -ne 0) {
            $fallbackStatus += [PSCustomObject]@{
                Name = $machineName
                State = 'unknown'
                StateHuman = 'unknown'
                Provider = 'virtualbox'
            }
            continue
        }

        $vmStateLine = @($result.StdOut | Where-Object { [string]$_ -match '^VMState=' } | Select-Object -First 1)
        $vmStateValue = if ($vmStateLine.Count -gt 0) {
            ([string]$vmStateLine[0] -replace '^VMState="?([^"]+)"?$', '$1')
        }
        else {
            'unknown'
        }

        $stateInfo = ConvertFrom-VirtualBoxState -State $vmStateValue
        $fallbackStatus += [PSCustomObject]@{
            Name = $machineName
            State = [string]$stateInfo.State
            StateHuman = [string]$stateInfo.StateHuman
            Provider = 'virtualbox'
        }
    }

    return @($fallbackStatus)
}

function Get-VmSshConfig {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vagrantPath = Get-VagrantPath

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le 12; $attempt++) {
            $result = Invoke-ExternalCapture -FilePath $vagrantPath -ArgumentList @('ssh-config', $MachineName)
            Wait-VagrantClientQuiescence | Out-Null

            if ($result.ExitCode -eq 0) {
                return @($result.StdOut)
            }

            $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
            if ($attempt -lt 12 -and $combinedOutput -match 'not yet ready for SSH') {
                Start-Sleep -Seconds 5
                continue
            }

            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            throw "Failed to read SSH config for $MachineName."
        }
    }
    finally {
        Pop-Location
    }

    throw "Failed to read SSH config for $MachineName."
}

function Get-VmSshConnectionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $configLines = @(Get-VmSshConfig -MachineName $MachineName -ProjectRoot $ProjectRoot)
    $values = @{}

    foreach ($line in $configLines) {
        if ($line -notmatch '^\s*([A-Za-z][A-Za-z0-9]+)\s+(.+?)\s*$') {
            continue
        }

        $key = $matches[1].ToLowerInvariant()
        $value = $matches[2].Trim()
        if (-not $values.ContainsKey($key)) {
            $values[$key] = @()
        }

        $values[$key] += $value
    }

    return [PSCustomObject]@{
        HostName = if ($values.ContainsKey('hostname')) { [string]$values['hostname'][0] } else { '127.0.0.1' }
        Port = if ($values.ContainsKey('port')) { [int]$values['port'][0] } else { 22 }
        User = if ($values.ContainsKey('user')) { [string]$values['user'][0] } else { 'vagrant' }
        IdentityFiles = if ($values.ContainsKey('identityfile')) { @($values['identityfile']) } else { @() }
        ConfigLines = $configLines
    }
}

function Test-SshBannerReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [int]$TimeoutMilliseconds = 4000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    $asyncResult = $null
    $stream = $null

    try {
        $asyncResult = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
            return $false
        }

        $client.EndConnect($asyncResult)
        $client.ReceiveTimeout = $TimeoutMilliseconds
        $stream = $client.GetStream()

        $buffer = New-Object byte[] 256
        $bannerBuilder = New-Object System.Text.StringBuilder
        $deadline = (Get-Date).AddMilliseconds($TimeoutMilliseconds)

        do {
            if ($stream.DataAvailable) {
                $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -le 0) {
                    break
                }

                [void]$bannerBuilder.Append([System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead))
                if ($bannerBuilder.ToString().Contains("`n")) {
                    break
                }
            }
            else {
                Start-Sleep -Milliseconds 100
            }
        } while ((Get-Date) -lt $deadline)

        $banner = $bannerBuilder.ToString().Trim()
        return $banner.StartsWith('SSH-')
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $asyncResult) {
            $asyncResult.AsyncWaitHandle.Close()
        }

        if ($null -ne $stream) {
            $stream.Dispose()
        }

        $client.Close()
    }
}

function Get-SshExecutablePath {
    $candidate = Get-Command ssh.exe -ErrorAction SilentlyContinue
    if ($null -ne $candidate -and -not [string]::IsNullOrWhiteSpace([string]$candidate.Source)) {
        return $candidate.Source
    }

    $standardPaths = @(
        'C:\Program Files\Vagrant\embedded\usr\bin\ssh.exe',
        (Join-Path $env:SystemRoot 'System32\OpenSSH\ssh.exe'),
        'C:\Windows\System32\OpenSSH\ssh.exe',
        'C:\Program Files\Git\usr\bin\ssh.exe',
        'C:\Program Files\Git\bin\ssh.exe'
    )

    foreach ($path in $standardPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path -PathType Leaf)) {
            return $path
        }
    }

    throw 'Unable to locate ssh.exe on this host.'
}

function Invoke-SshWithVmConfig {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string[]]$RemoteCommand = @(),
        [switch]$Interactive,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $sshPath = Get-SshExecutablePath
    $configLines = @(Get-VmSshConfig -MachineName $MachineName -ProjectRoot $ProjectRoot)
    $configPath = Join-Path ([System.IO.Path]::GetTempPath()) ("rhcsa-ssh-{0}.conf" -f ([System.Guid]::NewGuid().ToString('N')))

    try {
        Set-Content -Path $configPath -Value $configLines -Encoding ascii
        $argumentList = @('-F', $configPath, $MachineName) + @($RemoteCommand)

        if ($Interactive) {
            $argumentList = @(
                '-F', $configPath,
                '-o', 'PasswordAuthentication=yes',
                '-o', 'PreferredAuthentications=publickey,password',
                $MachineName
            ) + @($RemoteCommand)
            Invoke-InteractiveExternalCommand -FilePath $sshPath -ArgumentList $argumentList -FailureMessage "Failed to open an SSH session for $MachineName."
            return
        }

        return (Invoke-ExternalCapture -FilePath $sshPath -ArgumentList $argumentList)
    }
    finally {
        Remove-Item -Path $configPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-LabCheckScriptPath {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $stateRoot = Initialize-LabStateLayout -ProjectRoot $ProjectRoot
    $fileName = if ($MachineName -eq 'server') { 'check-server.sh' } else { 'check-client.sh' }
    return (Join-Path $stateRoot $fileName)
}

function Clear-LabCheckScriptState {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    foreach ($machineName in @('server', 'client')) {
        $scriptPath = Get-LabCheckScriptPath -MachineName $machineName -ProjectRoot $ProjectRoot
        Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-LabCheckProvisionerName {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName
    )

    if ($MachineName -eq 'server') {
        return 'check-server'
    }

    return 'check-client'
}

function Write-LabCheckScript {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $scriptPath = Get-LabCheckScriptPath -MachineName $MachineName -ProjectRoot $ProjectRoot
    $quotedCommand = ConvertTo-BashSingleQuotedString -Value $Command
    $content = @(
        '#!/usr/bin/env bash',
        'set -euo pipefail',
        "/bin/bash -lc $quotedCommand"
    ) -join "`n"

    Set-Utf8NoBomFile -Path $scriptPath -Content ($content + "`n")
    return $scriptPath
}

function New-SshSessionKeyFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName
    )

    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("rhcsa-{0}-{1}.key" -f $MachineName, [System.Guid]::NewGuid().ToString('N'))
    if ($PSCmdlet.ShouldProcess($tempPath, 'Create temporary SSH session key file')) {
        Copy-Item -Path $SourcePath -Destination $tempPath -Force

        if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
            $grantTarget = if (-not [string]::IsNullOrWhiteSpace([string]$env:USERNAME)) { "{0}:F" -f $env:USERNAME } else { '{0}:F' -f [System.Environment]::UserName }
            $null = & icacls.exe $tempPath '/inheritance:r' '/grant:r' $grantTarget
        }
    }

    return $tempPath
}

function Get-VmDirectSshLaunchSpec {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$BatchMode
    )

    $connectionInfo = Get-VmSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
    $sshPath = Get-SshExecutablePath
    $keySource = @($connectionInfo.IdentityFiles | Where-Object { $_ -match '\.rsa$' -and (Test-Path $_ -PathType Leaf) } | Select-Object -First 1)
    if ($keySource.Count -eq 0) {
        $keySource = @($connectionInfo.IdentityFiles | Where-Object { Test-Path $_ -PathType Leaf } | Select-Object -First 1)
    }

    if ($keySource.Count -eq 0) {
        throw "No SSH identity file was found for $MachineName."
    }

    $temporaryKeyPath = New-SshSessionKeyFile -SourcePath $keySource[0] -MachineName $MachineName
    $argumentList = @(
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'LogLevel=ERROR',
        '-o', 'IdentitiesOnly=yes',
        '-o', 'PubkeyAcceptedKeyTypes=+ssh-rsa',
        '-o', 'HostKeyAlgorithms=+ssh-rsa',
        '-i', $temporaryKeyPath,
        '-p', ([string]$connectionInfo.Port)
    )

    if ($BatchMode) {
        $argumentList += @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=5')
    }

    $argumentList += ("{0}@{1}" -f $connectionInfo.User, $connectionInfo.HostName)

    return [PSCustomObject]@{
        SshPath = $sshPath
        ArgumentList = $argumentList
        TemporaryKeyPath = $temporaryKeyPath
    }
}

function Open-VmSshSession {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    Test-VagrantSshConnectivity -MachineName $MachineName -ProjectRoot $ProjectRoot
    $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot

    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        $powershellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
        $sshArgs = @($launchSpec.ArgumentList | ForEach-Object { ConvertTo-PowerShellSingleQuotedString -Value ([string]$_) }) -join ', '
        $launchScript = @(
            ('$sshArgs = @({0})' -f $sshArgs),
            ('& {0} @sshArgs' -f (ConvertTo-PowerShellSingleQuotedString -Value $launchSpec.SshPath)),
            ('$code = $LASTEXITCODE'),
            ('Remove-Item -Path {0} -Force -ErrorAction SilentlyContinue' -f (ConvertTo-PowerShellSingleQuotedString -Value $launchSpec.TemporaryKeyPath)),
            ('exit $code')
        ) -join '; '

        Start-Process `
            -FilePath $powershellPath `
            -WorkingDirectory $ProjectRoot `
            -ArgumentList @('-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $launchScript) `
            | Out-Null

        return [PSCustomObject]@{
            Detached = $true
            MachineName = $MachineName
        }
    }

    try {
        Invoke-InteractiveExternalCommand `
            -FilePath $launchSpec.SshPath `
            -ArgumentList $launchSpec.ArgumentList `
            -FailureMessage "Failed to open an SSH session for $MachineName."
    }
    finally {
        Remove-Item -Path $launchSpec.TemporaryKeyPath -Force -ErrorAction SilentlyContinue
    }

    return [PSCustomObject]@{
        Detached = $false
        MachineName = $MachineName
    }
}

function ConvertTo-BashSingleQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    return "'{0}'" -f ($Value -replace "'", "'""'""'")
}

function ConvertTo-PowerShellSingleQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    return "'{0}'" -f ($Value -replace "'", "''")
}

function Test-VagrantSshConnectivity {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$RetryCount = 5,
        [int]$RetryDelaySeconds = 3
    )

    $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot | Where-Object { [string]$_.Name -eq $MachineName } | Select-Object -First 1)
    if ($machineStatus.Count -gt 0) {
        $stateHuman = [string]$machineStatus[0].StateHuman
        switch ($stateHuman) {
            'not created' {
                throw "$MachineName is not created. Run .\RHCSA.ps1 up first."
            }
            'poweroff' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed."
            }
            'saved' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed."
            }
            'paused' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed."
            }
        }
    }

    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $launchSpec = $null
        try {
            $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
            $result = Invoke-ExternalCapture -FilePath $launchSpec.SshPath -ArgumentList ($launchSpec.ArgumentList + @('true'))
        }
        finally {
            if ($null -ne $launchSpec -and -not [string]::IsNullOrWhiteSpace([string]$launchSpec.TemporaryKeyPath)) {
                Remove-Item -Path $launchSpec.TemporaryKeyPath -Force -ErrorAction SilentlyContinue
            }
        }

        if ($result.ExitCode -eq 0) {
            return
        }

        $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
        $isRetryable = $combinedOutput -match 'Permission denied|Connection refused|Connection reset|timed out|Connection closed|No route to host'
        if ($attempt -lt $RetryCount -and $isRetryable) {
            Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
            continue
        }

        Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
        throw "Failed to validate SSH connectivity for $MachineName."
    }
}

function Invoke-VagrantVmShellCommandCapture {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$RetryCount = 2,
        [int]$RetryDelaySeconds = 5
    )

    $vagrantPath = Get-VagrantPath
    $provisionerName = Get-LabCheckProvisionerName -MachineName $MachineName

    Clear-LabCheckScriptState -ProjectRoot $ProjectRoot
    Write-LabCheckScript -MachineName $MachineName -Command $Command -ProjectRoot $ProjectRoot | Out-Null

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $result = Invoke-ExternalCapture -FilePath $vagrantPath -ArgumentList @('provision', $MachineName, '--provision-with', $provisionerName, '--no-color')
            if ($result.ExitCode -eq 0) {
                return $result
            }

            $canRetry = $attempt -le $RetryCount -and (Test-TransientVagrantFailure -StdOut $result.StdOut -StdErr $result.StdErr)
            if ($canRetry) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            return $result
        }
    }
    finally {
        Pop-Location
        Clear-LabCheckScriptState -ProjectRoot $ProjectRoot
    }
}

function Test-BaselineOfflineRepoHealth {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $repoCommand = 'curl -fsS http://server/repo/BaseOS/repodata/repomd.xml >/dev/null && curl -fsS http://server/repo/AppStream/repodata/repomd.xml >/dev/null'

    Test-VagrantSshConnectivity -MachineName 'server' -ProjectRoot $ProjectRoot
    Test-VagrantSshConnectivity -MachineName 'client' -ProjectRoot $ProjectRoot

    $serverResult = Invoke-VagrantVmShellCommandCapture -MachineName 'server' -Command $repoCommand -ProjectRoot $ProjectRoot
    $clientResult = Invoke-VagrantVmShellCommandCapture -MachineName 'client' -Command $repoCommand -ProjectRoot $ProjectRoot

    $results = @(
        [PSCustomObject]@{
            MachineName = 'server'
            ExitCode = [int]$serverResult.ExitCode
            Passed = ([int]$serverResult.ExitCode -eq 0)
        }
        [PSCustomObject]@{
            MachineName = 'client'
            ExitCode = [int]$clientResult.ExitCode
            Passed = ([int]$clientResult.ExitCode -eq 0)
        }
    )

    $failedMachines = @($results | Where-Object { -not $_.Passed } | ForEach-Object { [string]$_.MachineName })

    return [PSCustomObject]@{
        Passed = ($failedMachines.Count -eq 0)
        FailedMachines = $failedMachines
        Results = $results
    }
}

function Get-VagrantMachineId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $id = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace($id)) {
        throw "Vagrant machine id file not found for '$MachineName'."
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
    if (Test-Path $idFile -PathType Leaf) {
        $id = (Get-Content $idFile -Raw).Trim()
        if (-not [string]::IsNullOrWhiteSpace($id)) {
            return $id
        }
    }

    $projectName = Split-Path -Leaf $ProjectRoot
    $vmNamePrefix = '{0}_{1}_' -f $projectName, $MachineName
    $vboxManage = Get-VBoxManagePath
    foreach ($listTarget in @('runningvms', 'vms')) {
        $result = Invoke-ExternalCapture -FilePath $vboxManage -ArgumentList @('list', $listTarget)
        if ($result.ExitCode -ne 0) {
            continue
        }

        foreach ($line in $result.StdOut) {
            if ($line -match '^"([^"]+)"\s+\{([0-9A-Fa-f-]+)\}$') {
                $vmName = [string]$matches[1]
                $vmId = [string]$matches[2]
                if (-not $vmName.StartsWith($vmNamePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    continue
                }

                $idDirectory = Split-Path -Parent $idFile
                if (-not (Test-Path -LiteralPath $idDirectory)) {
                    New-Item -ItemType Directory -Path $idDirectory -Force | Out-Null
                }

                Set-Utf8NoBomFile -Path $idFile -Content $vmId
                return $vmId
            }
        }
    }

    return $null
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

function Get-BaselineStatus {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot)
    $machineNames = @('server', 'client')
    $snapshotReady = @{}

    foreach ($machineName in $machineNames) {
        $snapshotReady[$machineName] = $false
        $idFile = Join-Path $ProjectRoot ".vagrant\machines\$machineName\virtualbox\id"
        if (-not (Test-Path $idFile -PathType Leaf)) {
            continue
        }

        try {
            $snapshotReady[$machineName] = [bool](Test-BaseSnapshot -MachineName $machineName -ProjectRoot $ProjectRoot)
        }
        catch {
            $snapshotReady[$machineName] = $false
        }
    }

    $runningCount = @($machineStatus | Where-Object { [string]$_.StateHuman -eq 'running' }).Count
    $createdCount = @($machineStatus | Where-Object { [string]$_.StateHuman -ne 'not created' }).Count
    $snapshotsReady = ($snapshotReady['server'] -and $snapshotReady['client'])

    $state = 'missing'
    $stateText = 'not built'
    if ($createdCount -eq 0) {
        $state = 'missing'
        $stateText = 'not built'
    }
    elseif ($snapshotsReady -and $runningCount -eq $machineNames.Count) {
        $state = 'ready'
        $stateText = 'ready'
    }
    elseif ($snapshotsReady) {
        $state = 'available'
        $stateText = 'available'
    }
    else {
        $state = 'incomplete'
        $stateText = 'incomplete'
    }

    return [PSCustomObject]@{
        State = $state
        StateText = $stateText
        SnapshotsReady = $snapshotsReady
        MachineStatus = $machineStatus
        SnapshotReady = [PSCustomObject]@{
            Server = $snapshotReady['server']
            Client = $snapshotReady['client']
        }
    }
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

    foreach ($machine in @('server', 'client')) {
        $machineId = Get-OptionalVagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($machineId)) {
            throw "Cannot create base snapshots because '$machine' has not been created yet."
        }

        $machineIdMap[$machine] = $machineId

        if ($ForceRefresh -or -not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
            $targetMachine += $machine
        }
    }

    if ($targetMachine.Count -eq 0) {
        return $false
    }

    Push-Location $ProjectRoot
    try {
        foreach ($machine in @('server', 'client')) {
            Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage -VagrantPath $vagrant
        }

        foreach ($machine in $targetMachine) {
            $vmId = [string]$machineIdMap[$machine]
            if (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot) {
                Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('delete', 'base-clean') -FailureMessage "Failed to delete existing base-clean snapshot for $machine." -VBoxManagePath $vboxManage
            }
            Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('take', 'base-clean', '--description=RHCSA-v9-simulator-clean-baseline') -FailureMessage "Failed to create base-clean snapshot for $machine." -VBoxManagePath $vboxManage
        }

        foreach ($machine in @('server', 'client')) {
            if (-not $machineIdMap.ContainsKey($machine)) {
                $machineIdMap[$machine] = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            }
        }

        Export-BaseSnapshotState -MachineIdMap $machineIdMap -ProjectRoot $ProjectRoot | Out-Null

        foreach ($machine in @('server', 'client')) {
            $vmId = $machineIdMap[$machine]
            Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to restart $machine after snapshot creation." -SuppressOutput
        }
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
        foreach ($machine in @('server', 'client')) {
            Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage -VagrantPath $vagrant
        }

        foreach ($machine in @('server', 'client')) {
            $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            $restoreSucceeded = $false
            $lastRestoreError = $null

            for ($attempt = 1; $attempt -le 3 -and -not $restoreSucceeded; $attempt++) {
                try {
                    $currentState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
                    if ($currentState -and $currentState.ToLowerInvariant() -notin @('poweroff', 'saved', 'aborted')) {
                        Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage -VagrantPath $vagrant
                    }

                    Invoke-VBoxSnapshotCommand -VmId $vmId -SnapshotArgumentList @('restore', 'base-clean') -FailureMessage "Failed to restore snapshot 'base-clean' for $machine." -VBoxManagePath $vboxManage
                    $restoreSucceeded = $true
                }
                catch {
                    $lastRestoreError = $_
                    $message = $_.ToString()
                    if ($attempt -lt 3 -and $message -match 'VBOX_E_INVALID_VM_STATE|machine state: Running') {
                        Stop-VBoxMachineForSnapshot -MachineName $machine -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage -VagrantPath $vagrant
                        Start-Sleep -Seconds (2 * $attempt)
                        continue
                    }

                    throw
                }
            }

            if (-not $restoreSucceeded -and $null -ne $lastRestoreError) {
                throw $lastRestoreError
            }
        }

        foreach ($machine in @('server', 'client')) {
            $vmId = Get-VagrantMachineId -MachineName $machine -ProjectRoot $ProjectRoot
            Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to start $machine after restoring base snapshots." -SuppressOutput
        }
    }
    finally {
        Pop-Location
    }
}

function Wait-VagrantGuestSshReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Area = 'scenario',
        [int]$MaxAttempts = 18,
        [int]$DelaySeconds = 10,
        [int]$RequiredSuccesses = 1,
        [int]$StabilizationDelaySeconds = 3
    )

    $consecutiveSuccesses = 0

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $connectionInfo = Get-VmSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
        if (Test-SshBannerReady -HostName $connectionInfo.HostName -Port $connectionInfo.Port) {
            $consecutiveSuccesses += 1
            if ($consecutiveSuccesses -ge $RequiredSuccesses) {
                Start-Sleep -Seconds $StabilizationDelaySeconds
                return
            }

            Write-WorkflowStatus -Area $Area -Message "Confirmed $MachineName SSH once; waiting for stable readiness ($consecutiveSuccesses/$RequiredSuccesses)"
            Start-Sleep -Seconds $StabilizationDelaySeconds
            continue
        }

        $consecutiveSuccesses = 0

        if ($attempt -lt $MaxAttempts) {
            Write-WorkflowStatus -Area $Area -Message "Waiting for $MachineName SSH readiness before provisioning ($attempt/$MaxAttempts)"
            Start-Sleep -Seconds $DelaySeconds
            continue
        }

        throw "Failed to confirm SSH banner readiness for $MachineName before provisioning."
    }
}

function Confirm-VagrantGuestProvisionReadiness {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$Area = 'scenario',
        [int]$MaxAttempts = 18,
        [int]$DelaySeconds = 10,
        [int]$RequiredSuccesses = 1,
        [int]$StabilizationDelaySeconds = 3,
        [switch]$AllowStartupRetry
    )

    try {
        Wait-VagrantGuestSshReady `
            -MachineName $MachineName `
            -ProjectRoot $ProjectRoot `
            -Area $Area `
            -MaxAttempts $MaxAttempts `
            -DelaySeconds $DelaySeconds `
            -RequiredSuccesses $RequiredSuccesses `
            -StabilizationDelaySeconds $StabilizationDelaySeconds
        return
    }
    catch {
        if (-not $AllowStartupRetry.IsPresent) {
            throw
        }

        Write-WorkflowStatus -Area $Area -Message "Retrying $MachineName startup after a transient post-restore SSH readiness failure"
        Invoke-VagrantMachineStep -MachineName $MachineName -ProjectRoot $ProjectRoot -RetryArea $Area
        Wait-VagrantGuestSshReady `
            -MachineName $MachineName `
            -ProjectRoot $ProjectRoot `
            -Area $Area `
            -MaxAttempts ([Math]::Max($MaxAttempts / 2, 8)) `
            -DelaySeconds $DelaySeconds `
            -RequiredSuccesses $RequiredSuccesses `
            -StabilizationDelaySeconds $StabilizationDelaySeconds
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
        Start-Sleep -Seconds 5

        Confirm-VagrantGuestProvisionReadiness -MachineName 'server' -ProjectRoot $ProjectRoot -AllowStartupRetry
        Confirm-VagrantGuestProvisionReadiness -MachineName 'client' -ProjectRoot $ProjectRoot -AllowStartupRetry

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ServerRelative)) {
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the server overlay for '$($Manifest.Id)'"
            Invoke-VagrantCommand -ArgumentList @('provision', 'server', '--provision-with', 'scenario-server', '--no-color') -FailureMessage "Failed to apply server scenario overlay for '$($Manifest.Id)'." -RetryArea 'scenario' -RetryMessage "Retrying the server overlay for '$($Manifest.Id)' after a transient SSH/provider failure"
        }

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ClientRelative)) {
            Confirm-VagrantGuestProvisionReadiness -MachineName 'client' -ProjectRoot $ProjectRoot -MaxAttempts 6 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 2 -AllowStartupRetry
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the client overlay for '$($Manifest.Id)'"
            Invoke-VagrantCommand -ArgumentList @('provision', 'client', '--provision-with', 'scenario-client', '--no-color') -FailureMessage "Failed to apply client scenario overlay for '$($Manifest.Id)'." -RetryArea 'scenario' -RetryMessage "Retrying the client overlay for '$($Manifest.Id)' after a transient SSH/provider failure" -RetryCount 3 -RetryDelaySeconds 10
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

    $machineToCheck = @('client')
    if ($Manifest.Flags.RequiresServer) {
        $machineToCheck = @('server', 'client')
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
            throw "The restored baseline snapshot is incomplete on $machine. Run .\RHCSA.ps1 up and verify the guest provisioning logs."
        }
    }

    return $true
}

function Test-ForceHostCleanupEnabled {
    param(
        [switch]$ForceHostCleanup
    )

    if ($ForceHostCleanup.IsPresent) {
        return $true
    }

    if ((Test-Path variable:script:ForceHostCleanup) -and [bool]$script:ForceHostCleanup) {
        return $true
    }

    return ($env:RHCSA_FORCE_HOST_CLEANUP -match '^(1|true|yes|on)$')
}

function Get-LabMachineIdList {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    return @(
        Get-OptionalVagrantMachineId -MachineName 'server' -ProjectRoot $ProjectRoot
        Get-OptionalVagrantMachineId -MachineName 'client' -ProjectRoot $ProjectRoot
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Test-ProcessCommandLineMatchesLab {
    param(
        [string]$CommandLine,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineIds = @()
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    $normalizedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if ($CommandLine.IndexOf($normalizedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        return $true
    }

    foreach ($machineId in @($MachineIds)) {
        if (-not [string]::IsNullOrWhiteSpace($machineId) -and $CommandLine.IndexOf($machineId, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}

function Invoke-LabHypervisorLockCleanup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([int])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceHostCleanup
    )

    if (-not $PSCmdlet.ShouldProcess($ProjectRoot, 'Clean stale Vagrant and VirtualBox processes for this lab')) {
        return 0
    }

    $machineStateRoot = Join-Path $ProjectRoot '.vagrant\machines'
    if (Test-Path -LiteralPath $machineStateRoot) {
        Get-ChildItem -Path $machineStateRoot -Filter 'action_*' -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
    }

    $forceCleanup = Test-ForceHostCleanupEnabled -ForceHostCleanup:$ForceHostCleanup
    $machineIds = @(Get-LabMachineIdList -ProjectRoot $ProjectRoot)
    $killed = 0

    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        $name = [string]$process.Name
        $commandLine = [string]$process.CommandLine
        $kill = $false

        if ($forceCleanup -and $name -in @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxSVC.exe')) {
            $kill = $true
        }
        elseif ($name -in @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxHeadless.exe', 'VirtualBoxVM.exe')) {
            $kill = Test-ProcessCommandLineMatchesLab -CommandLine $commandLine -ProjectRoot $ProjectRoot -MachineIds $machineIds
        }

        if ($kill) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
            $killed++
        }
    }

    Start-Sleep -Seconds 2
    if ($forceCleanup -and (Test-LabHypervisorBusy -ProjectRoot $ProjectRoot -ForceHostCleanup)) {
        $fallbackNames = @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxSVC.exe', 'VBoxHeadless.exe', 'VirtualBoxVM.exe')
        foreach ($process in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
            if ([string]$process.Name -in $fallbackNames) {
                Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
                $killed++
            }
        }
        Start-Sleep -Seconds 2
    }

    return $killed
}

function Test-LabHypervisorBusy {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceHostCleanup
    )

    $forceCleanup = Test-ForceHostCleanupEnabled -ForceHostCleanup:$ForceHostCleanup
    $machineIds = @(Get-LabMachineIdList -ProjectRoot $ProjectRoot)
    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        $name = [string]$process.Name
        if ($forceCleanup -and $name -in @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxSVC.exe', 'VBoxHeadless.exe', 'VirtualBoxVM.exe')) {
            return $true
        }

        if (
            $name -in @('ruby.exe', 'vagrant.exe', 'VBoxManage.exe', 'VBoxHeadless.exe', 'VirtualBoxVM.exe') -and
            (Test-ProcessCommandLineMatchesLab -CommandLine ([string]$process.CommandLine) -ProjectRoot $ProjectRoot -MachineIds $machineIds)
        ) {
            return $true
        }
    }

    return $false
}

function Wait-LabHypervisorQuiescence {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MaxAttempts = 20,
        [int]$DelaySeconds = 2,
        [switch]$ForceHostCleanup
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (-not (Test-LabHypervisorBusy -ProjectRoot $ProjectRoot -ForceHostCleanup:$ForceHostCleanup)) {
            return $true
        }
        Start-Sleep -Seconds $DelaySeconds
    }

    return $false
}

function Test-VagrantClientBusy {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [switch]$ForceHostCleanup
    )

    $forceCleanup = Test-ForceHostCleanupEnabled -ForceHostCleanup:$ForceHostCleanup
    $machineIds = @(Get-LabMachineIdList -ProjectRoot $ProjectRoot)
    $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        if ($forceCleanup -and [string]$process.Name -in @('ruby.exe', 'vagrant.exe')) {
            return $true
        }

        if (
            [string]$process.Name -in @('ruby.exe', 'vagrant.exe') -and
            (Test-ProcessCommandLineMatchesLab -CommandLine ([string]$process.CommandLine) -ProjectRoot $ProjectRoot -MachineIds $machineIds)
        ) {
            return $true
        }
    }

    return $false
}

function Wait-VagrantClientQuiescence {
    [OutputType([bool])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 2,
        [switch]$ForceHostCleanup
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (-not (Test-VagrantClientBusy -ProjectRoot $ProjectRoot -ForceHostCleanup:$ForceHostCleanup)) {
            return $true
        }
        Start-Sleep -Seconds $DelaySeconds
    }

    return $false
}

function Invoke-ClientRecoveryConsole {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath

    Push-Location $ProjectRoot
    try {
        Write-WorkflowStatus -Area 'scenario' -Message 'Opening the client recovery console'
        Invoke-ExternalCommand -FilePath (Get-VagrantPath) -ArgumentList @('halt', 'client', '-f') -FailureMessage 'Failed to stop client before starting recovery console.' -IgnoreExitCode
        $clientId = Get-VagrantMachineId -MachineName 'client' -ProjectRoot $ProjectRoot
        Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $clientId, '--type', 'gui') -FailureMessage 'Failed to start client in GUI mode for password recovery.'
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
        $notices += 'HeadlessClient is deprecated. Use .\RHCSA.ps1 start for password recovery scenarios.'
    }

    if ($RealisticMode) {
        $notices += 'RealisticMode is deprecated. Use .\RHCSA.ps1 start for password recovery scenarios.'
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

    $baselineStatus = Get-BaselineStatus -ProjectRoot $ProjectRoot
    if (-not $SkipEnvironmentRecovery -and [string]$baselineStatus.State -eq 'incomplete') {
        $notices += 'Detected an incomplete baseline from a prior failed run. Rebuilding it from scratch.'
        Remove-LabEnvironment -PreserveState -ProjectRoot $ProjectRoot | Out-Null
    }

    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
    Wait-LabHypervisorQuiescence | Out-Null
    Remove-OrphanLabDiskSet -ProjectRoot $ProjectRoot | Out-Null
    if ([string]::IsNullOrWhiteSpace((Get-OptionalVagrantMachineId -MachineName 'client' -ProjectRoot $ProjectRoot))) {
        Set-LabDiskGeneration -ProjectRoot $ProjectRoot | Out-Null
    }
    Initialize-ClientLabDiskSet -ProjectRoot $ProjectRoot | Out-Null

    $script:WorkflowProgressArea = 'baseline'
    $script:WorkflowProgressIndex = 0
    $script:WorkflowProgressTotal = if ($NoProvision) { 3 } else { 5 }

    try {
        Write-WorkflowStatus -Area 'baseline' -Message 'Preparing lab environment'

        try {
            Push-Location $ProjectRoot
            try {
                if ($NoProvision) {
                    Write-WorkflowStatus -Area 'baseline' -Message 'Starting server'
                    Invoke-VagrantMachineStep -MachineName 'server' -ProjectRoot $ProjectRoot
                    Write-WorkflowStatus -Area 'baseline' -Message 'Starting client'
                    Invoke-VagrantMachineStep -MachineName 'client' -ProjectRoot $ProjectRoot
                }
                else {
                    Write-WorkflowStatus -Area 'baseline' -Message 'Provisioning server'
                    Invoke-VagrantMachineStep -MachineName 'server' -Provision -ProjectRoot $ProjectRoot
                    Write-WorkflowStatus -Area 'baseline' -Message 'Provisioning client'
                    Invoke-VagrantMachineStep -MachineName 'client' -Provision -ProjectRoot $ProjectRoot
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
                Wait-LabHypervisorQuiescence | Out-Null
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

            if (
                -not $SkipEnvironmentRecovery -and
                $message -match 'client-disk[0-9]+(?:-[0-9A-Za-z_-]+)?\.vdi' -and
                $message -match 'VERR_ALREADY_EXISTS|VERR_FILE_NOT_FOUND|Invalid UUID or filename|Could not find file for the medium'
            ) {
                @(Remove-OrphanLabDiskSet -Force -ProjectRoot $ProjectRoot) | Out-Null
                $notices += 'Rebuilt the client lab disk set after a stale or missing disk error.'
                Set-LabDiskGeneration -ProjectRoot $ProjectRoot | Out-Null
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
            $snapshotReady = (Test-BaseSnapshot -MachineName 'server' -ProjectRoot $ProjectRoot) -and
                             (Test-BaseSnapshot -MachineName 'client' -ProjectRoot $ProjectRoot)
            if (-not $snapshotReady) {
                $notices += "Baseline VMs are running, but 'base-clean' snapshots were not created because -NoProvision was used."
            }
        }
        else {
            Write-WorkflowStatus -Area 'baseline' -Message 'Creating baseline snapshots'
            $createdBaseSnapshot = Invoke-BaseSnapshotInitialization -ProjectRoot $ProjectRoot -ForceRefresh
            $snapshotReady = $true
        }

        if (-not $NoProvision) {
            Write-WorkflowStatus -Area 'baseline' -Message 'Validating offline package repository'
            $repoHealth = Test-BaselineOfflineRepoHealth -ProjectRoot $ProjectRoot
            if (-not $repoHealth.Passed) {
                $failedLabel = ($repoHealth.FailedMachines -join ', ')
                if (-not $SkipEnvironmentRecovery) {
                    $notices += "Detected an incomplete offline package repo baseline on $failedLabel. Rebuilding it from scratch."
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

                throw "The offline package repo baseline is unavailable on $failedLabel. Run .\RHCSA.ps1 destroy and then .\RHCSA.ps1 up."
            }
        }

        $clearedActiveRun = $false
        if ($null -ne (Get-ActiveRunState -ProjectRoot $ProjectRoot)) {
            Clear-ActiveRunState -ProjectRoot $ProjectRoot
            $clearedActiveRun = $true
        }

        return [PSCustomObject]@{
            Skipped = $false
            Notices = $notices
            CreatedBaseSnapshot = $createdBaseSnapshot
            SnapshotReady = $snapshotReady
            ClearedActiveRun = $clearedActiveRun
        }
    }
    finally {
        Remove-Variable -Scope Script -Name WorkflowProgressArea -ErrorAction SilentlyContinue
        Remove-Variable -Scope Script -Name WorkflowProgressIndex -ErrorAction SilentlyContinue
        Remove-Variable -Scope Script -Name WorkflowProgressTotal -ErrorAction SilentlyContinue
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
        [ValidateSet('RHCSA9', 'RHCSA10', 'All', 'rhcsa9', 'rhcsa10', 'all')]
        [string]$Track = 'RHCSA9',
        [switch]$ForceRestart,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $modeLower = $Mode.ToLowerInvariant()
    $trackLower = ConvertTo-ScenarioTrack -Track $Track
    $manifest = Get-ScenarioManifest -ScenarioId $ScenarioId -ProjectRoot $ProjectRoot -Track $trackLower
    if ($modeLower -notin $manifest.SupportedModes) {
        throw "Scenario '$ScenarioId' does not support mode '$modeLower'. Supported modes: $($manifest.SupportedModes -join ', ')."
    }

    if (-not $PSCmdlet.ShouldProcess($ScenarioId, "Start scenario run in $modeLower mode")) {
        return $null
    }

    Initialize-LabStateLayout -ProjectRoot $ProjectRoot | Out-Null
    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null

    $previousActiveRun = Get-ScenarioStatus -ProjectRoot $ProjectRoot
    if (-not $ForceRestart.IsPresent -and
        $null -ne $previousActiveRun -and
        $previousActiveRun.ScenarioId -eq $ScenarioId -and
        $previousActiveRun.Mode -eq $modeLower) {
        return [PSCustomObject]@{
            Manifest = $manifest
            Mode = $modeLower
            RunArtifact = [PSCustomObject]@{
                RunId = $previousActiveRun.RunId
                GeneratedArtifact = [PSCustomObject]@{
                    RunBrief = $previousActiveRun.RunBrief
                }
            }
            StartedAt = [datetime]::Parse($previousActiveRun.StartedAt)
            EndsAt = [datetime]::Parse($previousActiveRun.EndsAt)
            BaselineResult = $null
            RestoreMethod = 'already-active'
            ReplacedActiveRun = $previousActiveRun
            AlreadyActive = $true
        }
    }

    $needsBaselineBootstrap = $false
    foreach ($machine in @('server', 'client')) {
        if (-not (Test-Path (Join-Path $ProjectRoot ".vagrant\machines\$machine\virtualbox\id"))) {
            $needsBaselineBootstrap = $true
        }
    }

    if (-not $needsBaselineBootstrap) {
        foreach ($machine in @('server', 'client')) {
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

    foreach ($machine in @('server', 'client')) {
        if (-not (Test-BaseSnapshot -MachineName $machine -ProjectRoot $ProjectRoot)) {
            throw "Missing 'base-clean' snapshot for $machine. Recreate the baseline with .\RHCSA.ps1 up and try again."
        }
    }

    $startedAt = Get-Date
    $endsAt = $startedAt.AddMinutes($manifest.TimeLimitMinutes)
    $runArtifact = Export-RunArtifact -Manifest $manifest -Mode $modeLower -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot
    try {
        Export-ActiveRunState -Manifest $manifest -Mode $modeLower -RunArtifact $runArtifact -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot | Out-Null
        if ($modeLower -eq 'lab') {
            $null = Initialize-LabExerciseCache -Manifest $manifest -ProjectRoot $ProjectRoot
        }

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
        ReplacedActiveRun = $previousActiveRun
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

    $tracks = @($activeRun.scenario.tracks)
    if ($tracks.Count -eq 0) {
        $tracks = @('rhcsa9')
    }

    $rhelMajor = 9
    if ($null -ne $activeRun.scenario.rhel_major) {
        $rhelMajor = [int]$activeRun.scenario.rhel_major
    }

    return [PSCustomObject]@{
        ScenarioId = [string]$activeRun.scenario.id
        Category = [string]$activeRun.scenario.category
        Title = [string]$activeRun.scenario.title
        Mode = [string]$activeRun.mode
        ObjectiveTags = @($activeRun.scenario.objective_tags)
        Tracks = $tracks
        RHELMajor = $rhelMajor
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

function Test-IsAssertiveExerciseCheck {
    param(
        [string]$Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $false
    }

    $trimmed = $Command.Trim()
    $assertivePatterns = @(
        '(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*q[A-Za-z]*(?:\s|$)',
        '(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*E[A-Za-z]*(?:\s|$)',
        '(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*F[A-Za-z]*(?:\s|$)',
        '(?i)\bgrep\b[^\r\n]*\s-[A-Za-z]*x[A-Za-z]*(?:\s|$)',
        '(^|\s)test\s',
        '(^|\s)\[\s',
        '(^|\s)\[\[\s',
        '(^|\s)!\s',
        '(?i)\bdiff\s',
        '(?i)\bcmp\s',
        '(?i)\bawk\b.*\bexit\b',
        '(?i)\bid\s+\S+',
        '(?i)\bvisudo\s+-cf\b',
        '(?i)\bsystemctl\s+is-enabled\b',
        '(?i)\bsystemctl\s+is-active\b',
        '(?i)\bmountpoint\s+-q\b',
        '(?i)\bfindmnt\b',
        '(?i)\bpodman\s+image\s+exists\b',
        '(?i)\bpodman\s+ps\b[^\r\n]*--format\b',
        '(?i)\brpm\s+-q\b',
        '(?i)\bgrubby\s+--info\b',
        '(?i)\bmatchpathcon\b',
        '(?i)\bstat\s+-c\b',
        '(?i)\bblkid\s+-o\s+value\b',
        '(?i)\bfirewall-cmd\b[^\r\n]*--query-(port|service)\b',
        '(?i)\bhostnamectl\s+--static\b',
        '(?i)\bgetenforce\b',
        '(?i)\bswapon\s+--noheadings\b',
        '(?i)\bgetent\s+passwd\b',
        '(?i)\bgetent\s+hosts\b',
        '(?i)\bchage\s+-l\b',
        '(?i)\bcrontab\s+-l\b',
        '(?i)\batq\b',
        '(?i)\bsemanage\s+port\s+-l\b',
        '(?i)\bcurl\b[^\r\n]*\s-f(?:[sS]*)(?:\s|$)',
        '(?i)\bssh\b[^\r\n]*\bBatchMode=yes\b'
    )

    foreach ($pattern in $assertivePatterns) {
        if ($trimmed -match $pattern) {
            return $true
        }
    }

    return $false
}

function Invoke-LabExerciseCheck {
    param(
        [string]$ScenarioId,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $activeRun = Get-ScenarioStatus -ProjectRoot $ProjectRoot
    if ($null -eq $activeRun) {
        throw 'No active lab run found. Start a lab first with .\RHCSA.ps1 start -Id <lab-id> -Mode Lab.'
    }

    if ([string]$activeRun.Mode -ne 'lab') {
        throw 'Automated check is available for labs only right now.'
    }

    if (-not [string]::IsNullOrWhiteSpace($ScenarioId) -and [string]$activeRun.ScenarioId -ne $ScenarioId) {
        throw "Active run is '$($activeRun.ScenarioId)'. Start '$ScenarioId' first or run .\RHCSA.ps1 check without -Id."
    }

    $exercise = Get-LabExerciseDefinition -ScenarioId ([string]$activeRun.ScenarioId) -ProjectRoot $ProjectRoot
    $checks = @($exercise.Checks)
    if ($checks.Count -eq 0) {
        return [PSCustomObject]@{
            ScenarioId = [string]$activeRun.ScenarioId
            Title = [string]$activeRun.Title
            Exercise = $exercise
            NoChecks = $true
            Passed = $false
            PassedCount = 0
            FailedCount = 0
            TotalCount = 0
            Results = @()
        }
    }

    $results = @()
    foreach ($check in $checks) {
        if (-not (Test-IsAssertiveExerciseCheck -Command $check.Command)) {
            $results += [PSCustomObject]@{
                Index = [int]$check.Index
                Target = [string]$check.Target
                OriginalCommand = [string]$check.OriginalCommand
                Command = [string]$check.Command
                ExitCode = 125
                Passed = $false
                StdOut = @()
                StdErr = @('Weak automated check in scenario metadata. Replace display-style commands with assertive commands that return non-zero when the task is incomplete.')
            }
            continue
        }

        $result = Invoke-VagrantVmShellCommandCapture -MachineName $check.Target -Command $check.Command -ProjectRoot $ProjectRoot
        $results += [PSCustomObject]@{
            Index = [int]$check.Index
            Target = [string]$check.Target
            OriginalCommand = [string]$check.OriginalCommand
            Command = [string]$check.Command
            ExitCode = [int]$result.ExitCode
            Passed = ([int]$result.ExitCode -eq 0)
            StdOut = @($result.StdOut)
            StdErr = @($result.StdErr)
        }
    }

    $passedCount = @($results | Where-Object { $_.Passed }).Count
    $failedCount = @($results | Where-Object { -not $_.Passed }).Count

    return [PSCustomObject]@{
        ScenarioId = [string]$activeRun.ScenarioId
        Title = [string]$activeRun.Title
        Exercise = $exercise
        NoChecks = $false
        Passed = ($failedCount -eq 0)
        PassedCount = $passedCount
        FailedCount = $failedCount
        TotalCount = @($results).Count
        Results = $results
    }
}

function Reset-ScenarioRun {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $activeRun = Get-ActiveRunState -ProjectRoot $ProjectRoot
    if ($null -eq $activeRun) {
        throw 'No active run found. Start one first with .\RHCSA.ps1 start -Id <scenario-id> -Mode Lab.'
    }

    if (-not $PSCmdlet.ShouldProcess([string]$activeRun.scenario.id, 'Reset scenario run')) {
        return $null
    }

    $tracks = @($activeRun.scenario.tracks)
    $track = if ($tracks.Count -gt 0) { [string]$tracks[0] } else { 'rhcsa9' }
    $mode = ([string]$activeRun.mode).Substring(0, 1).ToUpperInvariant() + ([string]$activeRun.mode).Substring(1)
    return Start-ScenarioRun -ScenarioId $activeRun.scenario.id -Mode $mode -Track $track -ForceRestart -ProjectRoot $ProjectRoot
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

    foreach ($machineName in @('server', 'client')) {
        $vmId = Get-OptionalVagrantMachineId -MachineName $machineName -ProjectRoot $ProjectRoot
        if ($vmId) {
            $match = $registeredVm | Where-Object { $_.Id -eq $vmId } | Select-Object -First 1
            if ($null -ne $match) {
                $candidate += $match
            }
        }
    }

    $namePattern = '^' + [regex]::Escape($projectName) + '_(server|client)_'
    $legacyPattern = '^rhcsa-ex200-(server|client)'

    foreach ($machine in $registeredVm) {
        if ($machine.Name -match $namePattern -or $machine.Name -match $legacyPattern) {
            if (-not ($candidate | Where-Object { $_.Id -eq $machine.Id })) {
                $candidate += $machine
            }
        }
    }

    return @($candidate | Sort-Object Id -Unique)
}

function Remove-OrphanLabDiskSet {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object[]])]
    param(
        [ValidateSet('client')]
        [string]$MachineName = 'client',
        [switch]$Force,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $diskRoot = Join-Path $ProjectRoot '.lab-disks'
    if (-not (Test-Path -LiteralPath $diskRoot)) {
        return @()
    }

    $vboxManage = Get-OptionalVBoxManagePath
    $shouldPrune = $Force.IsPresent
    $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if (-not $shouldPrune -and [string]::IsNullOrWhiteSpace($vmId)) {
        $shouldPrune = $true
    }
    elseif (-not $shouldPrune) {
        if ($vboxManage) {
            $registeredVm = @(Get-VBoxVmCatalog -VBoxManagePath $vboxManage)
            if (-not (Test-VBoxVmRegistration -RegisteredVm $registeredVm -VmId $vmId)) {
                $shouldPrune = $true
            }
        }
    }

    if (-not $shouldPrune) {
        return @()
    }

    if ($vboxManage) {
        try {
            Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $diskRoot
        }
        catch {
            Write-Verbose "Ignoring VirtualBox disk cleanup failure while pruning orphaned lab disks in '$diskRoot'."
        }
    }

    $removed = @()
    Get-ChildItem -LiteralPath $diskRoot -Filter ("{0}-disk*.vdi" -f $MachineName) -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove orphaned lab disk file')) {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path -LiteralPath $_.FullName)) {
                    $removed += $_.FullName
                }
            }
        }

    return @($removed)
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
    $parentUuid = $null

    foreach ($line in $result.StdOut) {
        if ($line -match '^UUID:\s+(.+)$') {
            if ($uuid -and $location) {
                $items += [PSCustomObject]@{
                    UUID = $uuid
                    Location = $location
                    ParentUUID = $parentUuid
                }
            }

            $uuid = $matches[1].Trim()
            $location = $null
            $parentUuid = $null
            continue
        }

        if ($line -match '^Location:\s+(.+)$') {
            $location = $matches[1].Trim()
            continue
        }

        if ($line -match '^Parent UUID:\s+(.+)$') {
            $parentUuid = $matches[1].Trim()
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($uuid -and $location) {
                $items += [PSCustomObject]@{
                    UUID = $uuid
                    Location = $location
                    ParentUUID = $parentUuid
                }
            }

            $uuid = $null
            $location = $null
            $parentUuid = $null
        }
    }

    if ($uuid -and $location) {
        $items += [PSCustomObject]@{
            UUID = $uuid
            Location = $location
            ParentUUID = $parentUuid
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

    $folderFull = if (Test-Path -LiteralPath $FolderPath) {
        (Resolve-Path -LiteralPath $FolderPath).Path
    }
    else {
        [System.IO.Path]::GetFullPath($FolderPath)
    }
    $folderNorm = $folderFull.Replace('/', '\').ToLowerInvariant().TrimEnd('\') + '\'

    $hardDiskCatalog = @(Get-VBoxHardDiskCatalog -VBoxManagePath $VBoxManagePath)
    $targetDisks = @($hardDiskCatalog | Where-Object {
        $_.Location.Replace('/', '\').ToLowerInvariant().StartsWith($folderNorm)
    })

    if ($targetDisks.Count -eq 0) {
        return
    }

    $diskByUuid = @{}
    foreach ($hardDisk in $targetDisks) {
        $diskByUuid[$hardDisk.UUID] = $hardDisk
    }

    $depthMemo = @{}
    function Get-VBoxDiskDepth {
        param([string]$Uuid)

        if ($depthMemo.ContainsKey($Uuid)) {
            return $depthMemo[$Uuid]
        }

        $item = $diskByUuid[$Uuid]
        if ($null -eq $item -or [string]::IsNullOrWhiteSpace($item.ParentUUID) -or -not $diskByUuid.ContainsKey($item.ParentUUID)) {
            $depthMemo[$Uuid] = 0
            return 0
        }

        $depth = 1 + (Get-VBoxDiskDepth -Uuid $item.ParentUUID)
        $depthMemo[$Uuid] = $depth
        return $depth
    }

    $targetDisks = @($targetDisks | Sort-Object -Property @{ Expression = { Get-VBoxDiskDepth -Uuid $_.UUID }; Descending = $true })
    foreach ($hardDisk in $targetDisks) {
        foreach ($argumentList in @(
            @('closemedium', 'disk', $hardDisk.UUID, '--delete'),
            @('closemedium', 'disk', $hardDisk.UUID),
            @('closemedium', 'disk', $hardDisk.Location, '--delete'),
            @('closemedium', 'disk', $hardDisk.Location)
        )) {
            $exitCode = Invoke-ExternalCommand `
                -FilePath $VBoxManagePath `
                -ArgumentList $argumentList `
                -FailureMessage "Failed to close VirtualBox medium '$($hardDisk.UUID)'." `
                -IgnoreExitCode `
                -PassThruExitCode `
                -SuppressOutput
            if ($exitCode -eq 0) {
                break
            }
        }
    }
}

function Initialize-VBoxLabDiskFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [int]$SizeMB,
        [switch]$SkipFolderCleanup,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string]$VBoxManagePath = (Get-VBoxManagePath)
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $Path) -and (Get-Item -LiteralPath $Path).Length -gt 0) {
        return $Path
    }

    if (-not $SkipFolderCleanup) {
        Invoke-VBoxHardDiskCleanup -VBoxManagePath $VBoxManagePath -FolderPath (Get-LabDisksRoot -ProjectRoot $ProjectRoot)
    }
    Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue

    if ($PSCmdlet.ShouldProcess($Path, "Create $SizeMB MB VirtualBox disk")) {
        $result = Invoke-ExternalCapture -FilePath $VBoxManagePath -ArgumentList @(
            'createmedium', 'disk',
            '--filename', $Path,
            '--size', $SizeMB.ToString(),
            '--format', 'VDI'
        )

        if ($result.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $Path)) {
            throw "Failed to create VDI ${Path}: $((@($result.StdOut + $result.StdErr) -join [Environment]::NewLine).Trim())"
        }
    }

    return $Path
}

function Initialize-ClientLabDiskSet {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object[]])]
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $vboxManage = Get-VBoxManagePath
    $paths = @(
        (Get-ClientLabDiskPath -DiskNumber 1 -ProjectRoot $ProjectRoot),
        (Get-ClientLabDiskPath -DiskNumber 2 -ProjectRoot $ProjectRoot)
    )

    $needsRebuild = $false
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            $needsRebuild = $true
            break
        }

        $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
        if ($null -eq $item -or $item.Length -le 0) {
            $needsRebuild = $true
            break
        }
    }

    if ($needsRebuild) {
        Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath (Get-LabDisksRoot -ProjectRoot $ProjectRoot)
    }

    foreach ($path in $paths) {
        Initialize-VBoxLabDiskFile -Path $path -SizeMB 2048 -SkipFolderCleanup:$needsRebuild -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage | Out-Null
    }

    return $paths
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
        "${ProjectName}_server_*",
        "${ProjectName}_client_*",
        'rhcsa-ex200-server*',
        'rhcsa-ex200-client*'
    )

    foreach ($pattern in $patterns) {
        Get-ChildItem -LiteralPath $VBoxMachineFolder -Directory -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
    }
}

function Invoke-LiteralPathRemovalWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,
        [switch]$Recurse,
        [switch]$Force,
        [int]$MaxAttempts = 5
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (-not (Test-Path -LiteralPath $LiteralPath)) {
            return $true
        }

        try {
            Remove-Item -LiteralPath $LiteralPath -Recurse:$Recurse -Force:$Force -ErrorAction Stop
        }
        catch {
            Start-Sleep -Milliseconds ([Math]::Min(250 * $attempt, 1000))
        }

        if (-not (Test-Path -LiteralPath $LiteralPath)) {
            return $true
        }
    }

    return (-not (Test-Path -LiteralPath $LiteralPath))
}

function Test-LocalLabArtifactsPresent {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $paths = @(
        (Join-Path $ProjectRoot '.vagrant'),
        (Join-Path $ProjectRoot '.lab-state'),
        (Join-Path $ProjectRoot '.lab-disks'),
        (Join-Path $ProjectRoot 'output'),
        (Join-Path $ProjectRoot 'builds'),
        (Join-Path $ProjectRoot 'packer_cache')
    )

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            return $true
        }
    }

    if (Get-ChildItem -Path $ProjectRoot -Filter '*.vdi' -File -ErrorAction SilentlyContinue | Select-Object -First 1) {
        return $true
    }

    return $false
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
            AlreadyClean = $false
            Notes = $notes
            RemovedPaths = @()
            RemainingPaths = @()
            RemainingVms = @()
            CleanupComplete = $true
        }
    }

    if (-not (Test-LocalLabArtifactsPresent -ProjectRoot $ProjectRoot)) {
        return [PSCustomObject]@{
            Skipped = $false
            AlreadyClean = $true
            Notes = @('No local simulator state was present.')
            RemovedPaths = @()
            RemainingPaths = @()
            RemainingVms = @()
            CleanupComplete = $true
        }
    }

    Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null

    $projectName = Split-Path -Leaf $ProjectRoot
    $vboxManage = Get-OptionalVBoxManagePath
    $vboxMachineFolder = if ($vboxManage) { Get-VBoxMachineFolder -VBoxManagePath $vboxManage } else { $null }

    $labDisksDir = Join-Path $ProjectRoot '.lab-disks'
    $legacyDisksDir = Join-Path $ProjectRoot '.vagrant\disks'
    $removedPaths = @()
    $remainingPaths = @()
    $remainingVms = @()

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
            Wait-LabHypervisorQuiescence | Out-Null

            foreach ($candidate in (Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)) {
                Invoke-VBoxVmRemoval -VBoxManagePath $vboxManage -VmId $candidate.Id
            }

            try {
                Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $labDisksDir
                Invoke-VBoxHardDiskCleanup -VBoxManagePath $vboxManage -FolderPath $legacyDisksDir
            }
            catch {
                $notes += 'VirtualBox left stale disk registrations behind. Continuing with local disk cleanup.'
            }
            Invoke-OrphanVmFolderCleanup -VBoxMachineFolder $vboxMachineFolder -ProjectName $projectName
            Invoke-LabHypervisorLockCleanup -ProjectRoot $ProjectRoot | Out-Null
            Wait-LabHypervisorQuiescence | Out-Null
            $remainingVms = @(Get-LabVBoxVmCandidate -ProjectRoot $ProjectRoot -VBoxManagePath $vboxManage)
            if ($remainingVms.Count -gt 0) {
                $notes += ('VirtualBox still reports lab VM(s): {0}' -f (($remainingVms | ForEach-Object { $_.Name }) -join ', '))
            }
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
                if (Invoke-LiteralPathRemovalWithRetry -LiteralPath $path -Recurse -Force) {
                    $removedPaths += $path
                }
                else {
                    $remainingPaths += $path
                }
            }
        }

        Get-ChildItem -Path . -Filter '*.vdi' -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                if (Invoke-LiteralPathRemovalWithRetry -LiteralPath $_.FullName -Force) {
                    $removedPaths += $_.FullName
                }
                else {
                    $remainingPaths += $_.FullName
                }
            }

        if ($remainingPaths.Count -gt 0) {
            $notes += ('Local state path(s) still present: {0}' -f ($remainingPaths -join ', '))
        }
    }
    finally {
        Pop-Location
    }

    return [PSCustomObject]@{
        Skipped = $false
        AlreadyClean = $false
        Notes = $notes
        RemovedPaths = $removedPaths
        RemainingPaths = $remainingPaths
        RemainingVms = $remainingVms
        CleanupComplete = (($remainingPaths.Count -eq 0) -and ($remainingVms.Count -eq 0))
    }
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
