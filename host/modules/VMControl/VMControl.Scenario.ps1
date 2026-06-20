# Dot-sourced by VMControl.psm1. Keep functions in this file internal unless exported by VMControl.psd1.

function Get-ScenarioProvisionEnvironment {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $environment = @{}
    $activeRun = Get-ActiveRunState -ProjectRoot $ProjectRoot
    if ($null -eq $activeRun) {
        return $environment
    }

    if ($null -ne $activeRun.PSObject.Properties['run_id']) {
        $environment.RHCSA_RUN_ID = [string]$activeRun.run_id
    }

    if ($null -ne $activeRun.PSObject.Properties['mode']) {
        $environment.RHCSA_SCENARIO_MODE = [string]$activeRun.mode
    }

    $scenarioId = $null
    if ($null -ne $activeRun.PSObject.Properties['scenario'] -and $null -ne $activeRun.scenario -and $null -ne $activeRun.scenario.PSObject.Properties['id']) {
        $scenarioId = [string]$activeRun.scenario.id
    }
    elseif ($null -ne $activeRun.PSObject.Properties['scenario_id']) {
        $scenarioId = [string]$activeRun.scenario_id
    }

    if (-not [string]::IsNullOrWhiteSpace($scenarioId)) {
        $environment.RHCSA_SCENARIO_ID = $scenarioId
    }

    return $environment
}

function Invoke-ScenarioProvisioning {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    Push-Location $ProjectRoot
    try {
        $scenarioEnvironment = Get-ScenarioProvisionEnvironment -ProjectRoot $ProjectRoot
        $needsServerReadiness = [bool]$Manifest.Flags.RequiresServer -or -not [string]::IsNullOrWhiteSpace([string]$Manifest.VmScripts.ServerRelative)
        if ($needsServerReadiness) {
            Confirm-VagrantGuestProvisionReadiness -MachineName 'server' -ProjectRoot $ProjectRoot -AllowStartupRetry
        }
        Confirm-VagrantGuestProvisionReadiness -MachineName 'client' -ProjectRoot $ProjectRoot -AllowStartupRetry

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ServerRelative)) {
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the server overlay for '$($Manifest.Id)'"
            Invoke-VagrantVmScript `
                -MachineName 'server' `
                -ScriptPath $Manifest.VmScripts.Server `
                -ProvisionerName 'scenario-server' `
                -ProjectRoot $ProjectRoot `
                -RetryArea 'scenario' `
                -Environment $scenarioEnvironment `
                -RetryMessage "Retrying the server overlay for '$($Manifest.Id)' after a transient SSH/provider failure" `
                -TimeoutSeconds 900 `
                -SkipVagrantFallback | Out-Null
        }

        if (-not [string]::IsNullOrWhiteSpace($Manifest.VmScripts.ClientRelative)) {
            Confirm-VagrantGuestProvisionReadiness -MachineName 'client' -ProjectRoot $ProjectRoot -MaxAttempts 6 -DelaySeconds 5 -RequiredSuccesses 1 -StabilizationDelaySeconds 2 -AllowStartupRetry
            Write-WorkflowStatus -Area 'scenario' -Message "Applying the client overlay for '$($Manifest.Id)'"
            Invoke-VagrantVmScript `
                -MachineName 'client' `
                -ScriptPath $Manifest.VmScripts.Client `
                -ProvisionerName 'scenario-client' `
                -ProjectRoot $ProjectRoot `
                -RetryCount 3 `
                -RetryDelaySeconds 10 `
                -TimeoutSeconds 900 `
                -RetryArea 'scenario' `
                -Environment $scenarioEnvironment `
                -RetryMessage "Retrying the client overlay for '$($Manifest.Id)' after a transient SSH/provider failure" `
                -SkipVagrantFallback | Out-Null
        }
    }
    finally {
        Pop-Location
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
        [string]$Track = 'RHCSA10',
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

    if (-not $needsBaselineBootstrap -and -not (Test-BaseSnapshotModeReady -ProjectRoot $ProjectRoot)) {
        $needsBaselineBootstrap = $true
    }

    $baselineResult = $null
    $restoreMethod = 'snapshot'
    $restoreMachineNames = @('server', 'client')
    if (
        $modeLower -eq 'lab' -and
        -not [bool]$manifest.Flags.RequiresServer -and
        [string]::IsNullOrWhiteSpace([string]$manifest.VmScripts.ServerRelative)
    ) {
        $restoreMachineNames = @('client')
    }

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
            if ($null -eq $previousActiveRun -and (Test-LiveCleanBaselineAvailable -ProjectRoot $ProjectRoot -MachineNames $restoreMachineNames)) {
                $restoreMethod = 'live-clean-baseline'
                Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
            }
            else {
                Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
                Invoke-BaseSnapshotRestore -ProjectRoot $ProjectRoot -MachineNames $restoreMachineNames
            }
        }
        catch {
            $restoreFailureMessage = $_.ToString()
            $baselineStatusAfterRestoreFailure = Get-BaselineStatus -ProjectRoot $ProjectRoot
            $canRecoverRestoreFailure = $restoreFailureMessage -match 'Failed to confirm SSH readiness|still reported as not created after startup|did not reach state|Direct SSH command did not return the RHCSA exit marker|VBoxHeadless|VirtualBox VM .* remained locked|Failed to restore snapshot'
            if ([string]$baselineStatusAfterRestoreFailure.State -in @('ready', 'available') -and -not $canRecoverRestoreFailure) {
                throw
            }

            $restoreMethod = 'baseline-rebuild'
            if ($canRecoverRestoreFailure) {
                $baseState = Get-BaseSnapshotState -ProjectRoot $ProjectRoot
                $stateModeProperty = if ($null -ne $baseState) { $baseState.PSObject.Properties['snapshot_mode'] } else { $null }
                if (
                    (Get-ProjectProfile -ProjectRoot $ProjectRoot) -eq 'rhel10' -and
                    $null -ne $stateModeProperty -and
                    [string]$stateModeProperty.Value -eq 'saved'
                ) {
                    Disable-Rhel10SavedSnapshotForHost -ProjectRoot $ProjectRoot -Reason $restoreFailureMessage
                }
                $cleanupParameters = @{ ProjectRoot = $ProjectRoot }
                if (Test-ForceHostCleanupEnabled) {
                    $cleanupParameters['ForceHostCleanup'] = $true
                }
                Remove-LabEnvironment @cleanupParameters | Out-Null
            }
            $baselineResult = Start-BaselineSession -ProjectRoot $ProjectRoot
            Clear-LiveCleanBaselineState -ProjectRoot $ProjectRoot
        }

        $null = Repair-BaselineSnapshotIfNeeded -Manifest $manifest -ProjectRoot $ProjectRoot

        Invoke-ScenarioProvisioning -Manifest $manifest -ProjectRoot $ProjectRoot
        $startedAt = Get-Date
        $endsAt = $startedAt.AddMinutes($manifest.TimeLimitMinutes)
        $briefPath = Join-Path $ProjectRoot ([string]$runArtifact.GeneratedArtifact.RunBrief)
        Set-Utf8NoBomFile -Path $briefPath -Content (Format-RunBriefText -Manifest $manifest -Mode $modeLower -StartedAt $startedAt -EndsAt $endsAt)
        Export-ActiveRunState -Manifest $manifest -Mode $modeLower -RunArtifact $runArtifact -StartedAt $startedAt -EndsAt $endsAt -ProjectRoot $ProjectRoot | Out-Null

        if ($manifest.Flags.PasswordRecovery -and $env:RHCSA_SKIP_RECOVERY_CONSOLE -notmatch '^(1|true|yes|on)$') {
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
        '(?i)\btest\s',
        '(^|[\s''"])\[\s',
        '(^|[\s''"])\[\[\s',
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
        '(?i)^\s*pvs(?:\s|$)',
        '(?i)^\s*vgs(?:\s|$)',
        '(?i)^\s*lvs(?:\s|$)',
        '(?i)\brpm\s+-q\b',
        '(?i)\bgrubby\s+--info\b',
        '(?i)\bmatchpathcon\b',
        '(?i)\bstat\s+-c\b',
        '(?i)\bblkid\s+-o\s+value\b',
        '(?i)\bfirewall-cmd\b[^\r\n]*--query-(port|service)\b',
        '(?i)\bhostnamectl\s+--static\b',
        '(?i)\bgetenforce\b',
        '(?i)\bswapon\s+--noheadings\b',
        '(?i)\bgetent\s+(passwd|group|hosts)\b',
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

    $tracks = @($activeRun.Tracks)
    $track = if ($tracks.Count -gt 0) { [string]$tracks[0] } else { 'rhcsa9' }
    $exercise = Get-LabExerciseDefinition -ScenarioId ([string]$activeRun.ScenarioId) -ProjectRoot $ProjectRoot -Track $track
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

        $result = Invoke-VagrantVmShellCommandCapture -MachineName $check.Target -Command $check.Command -ProjectRoot $ProjectRoot -SkipVagrantFallback
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

