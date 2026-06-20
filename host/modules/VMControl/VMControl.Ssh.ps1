# Dot-sourced by VMControl.psm1. Keep functions in this file internal unless exported by VMControl.psd1.

function Get-VmSshReadinessCommand {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    return 'printf __RHCSA_SSH_READY__'
}

function Get-VmSshConnectionCacheKey {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    return ('{0}|{1}' -f ([System.IO.Path]::GetFullPath($ProjectRoot)).ToLowerInvariant(), $MachineName.ToLowerInvariant())
}

function Clear-VmSshConnectionCache {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineNames = @()
    )

    $targets = @($MachineNames | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
    if ($targets.Count -eq 0) {
        $prefix = ('{0}|' -f ([System.IO.Path]::GetFullPath($ProjectRoot)).ToLowerInvariant())
        foreach ($key in @($script:VmSshConnectionCache.Keys)) {
            if ([string]$key -like "$prefix*") {
                $script:VmSshConnectionCache.Remove($key) | Out-Null
            }
        }
        return
    }

    foreach ($machineName in $targets) {
        $key = Get-VmSshConnectionCacheKey -MachineName $machineName -ProjectRoot $ProjectRoot
        if ($script:VmSshConnectionCache.ContainsKey($key)) {
            $script:VmSshConnectionCache.Remove($key) | Out-Null
        }
    }
}

function Remove-VagrantActionMarkers {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [string[]]$MachineNames = @()
    )

    $machineStateRoot = Join-Path $ProjectRoot '.vagrant\machines'
    if (-not (Test-Path -LiteralPath $machineStateRoot)) {
        return
    }

    $targets = @($MachineNames | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object {
        Join-Path $machineStateRoot "$_\virtualbox"
    })
    if ($targets.Count -eq 0) {
        $targets = @($machineStateRoot)
    }

    foreach ($target in $targets) {
        if (-not (Test-Path -LiteralPath $target)) {
            continue
        }

        Get-ChildItem -Path $target -Filter 'action_*' -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
    }
}

function Get-DefaultVagrantIdentityFiles {
    [OutputType([string[]])]
    param()

    $userProfile = [System.Environment]::GetFolderPath('UserProfile')
    $candidatePaths = @(
        (Join-Path $userProfile '.vagrant.d\insecure_private_keys\vagrant.key.ed25519'),
        (Join-Path $userProfile '.vagrant.d\insecure_private_key'),
        (Join-Path $userProfile '.vagrant.d\insecure_private_keys\vagrant.key.rsa')
    )

    $keyDirectory = Join-Path $userProfile '.vagrant.d\insecure_private_keys'
    if (Test-Path -LiteralPath $keyDirectory -PathType Container) {
        $candidatePaths += @(
            Get-ChildItem -Path $keyDirectory -File -ErrorAction SilentlyContinue |
                Sort-Object {
                    switch -Regex ($_.Name) {
                        '^vagrant\.key\.ed25519$' { '00' }
                        '^vagrant\.key\.rsa$' { '10' }
                        default { '20_{0}' -f $_.Name }
                    }
                } |
                ForEach-Object { $_.FullName }
        )
    }

    return @(
        $candidatePaths |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
            Select-Object -Unique
    )
}

function Get-VagrantMachineIdentityFiles {
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $machineKey = Join-Path $ProjectRoot ".vagrant\machines\$MachineName\virtualbox\private_key"
    $candidatePaths = @($machineKey) + @(Get-DefaultVagrantIdentityFiles)
    return @(
        $candidatePaths |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
            Select-Object -Unique
    )
}

function ConvertTo-VmSshConfigLines {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [object]$ConnectionInfo
    )

    $lines = @(
        "Host $MachineName",
        "  HostName $([string]$ConnectionInfo.HostName)",
        "  User $([string]$ConnectionInfo.User)",
        "  Port $([string]$ConnectionInfo.Port)",
        '  UserKnownHostsFile /dev/null',
        '  StrictHostKeyChecking no',
        '  LogLevel ERROR',
        '  IdentitiesOnly yes',
        '  BatchMode yes',
        '  PreferredAuthentications publickey',
        '  PasswordAuthentication no',
        '  KbdInteractiveAuthentication no',
        '  NumberOfPasswordPrompts 0'
    )

    foreach ($identityFile in @($ConnectionInfo.IdentityFiles | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })) {
        $identityPath = ([string]$identityFile -replace '\\', '/') -replace '"', '\"'
        $lines += ('  IdentityFile "{0}"' -f $identityPath)
    }

    return $lines
}

function Get-VirtualBoxSshConnectionInfo {
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    try {
        $machineId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    }
    catch {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($machineId)) {
        return $null
    }

    $vboxManage = Get-OptionalVBoxManagePath
    if (-not $vboxManage) {
        return $null
    }

    $result = Invoke-ExternalCapture -FilePath $vboxManage -ArgumentList @('showvminfo', $machineId, '--machinereadable') -TimeoutSeconds 20
    if ($result.ExitCode -ne 0) {
        return $null
    }

    foreach ($line in @($result.StdOut)) {
        $text = [string]$line
        if ($text -notmatch '^Forwarding\(\d+\)="([^"]+)"$') {
            continue
        }

        $parts = @($matches[1] -split ',', 6)
        if ($parts.Count -lt 6) {
            continue
        }

        $ruleName = [string]$parts[0]
        $protocol = [string]$parts[1]
        $hostName = [string]$parts[2]
        $hostPortText = [string]$parts[3]
        $guestPortText = [string]$parts[5]

        if ($protocol -ne 'tcp') {
            continue
        }

        if ($ruleName -ne 'ssh' -and $guestPortText -ne '22') {
            continue
        }

        $hostPort = 0
        if (-not [int]::TryParse($hostPortText, [ref]$hostPort) -or $hostPort -le 0) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($hostName) -or $hostName -eq '0.0.0.0') {
            $hostName = '127.0.0.1'
        }

        $connectionInfo = [PSCustomObject]@{
            MachineId = $machineId
            HostName = $hostName
            Port = $hostPort
            User = 'vagrant'
            IdentityFiles = @(Get-VagrantMachineIdentityFiles -MachineName $MachineName -ProjectRoot $ProjectRoot)
        }

        $connectionInfo | Add-Member -NotePropertyName ConfigLines -NotePropertyValue @(ConvertTo-VmSshConfigLines -MachineName $MachineName -ConnectionInfo $connectionInfo)
        return $connectionInfo
    }

    return $null
}

function Get-VmSshConfig {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $localConnectionInfo = Get-VirtualBoxSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ($null -ne $localConnectionInfo) {
        return @($localConnectionInfo.ConfigLines)
    }

    $vagrantCommand = Get-VagrantCommandSpec

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le 12; $attempt++) {
            $result = Invoke-ExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('ssh-config', $MachineName)) -TimeoutSeconds 30
            Wait-VagrantClientQuiescence | Out-Null

            if ($result.ExitCode -eq 0 -and -not (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
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

    $cacheKey = Get-VmSshConnectionCacheKey -MachineName $MachineName -ProjectRoot $ProjectRoot
    $machineId = $null
    try {
        $machineId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    }
    catch {
        $machineId = $null
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$machineId) -and $script:VmSshConnectionCache.ContainsKey($cacheKey)) {
        $cachedConnectionInfo = $script:VmSshConnectionCache[$cacheKey]
        if ($null -ne $cachedConnectionInfo -and [string]$cachedConnectionInfo.MachineId -eq [string]$machineId) {
            return $cachedConnectionInfo
        }
    }

    $localConnectionInfo = Get-VirtualBoxSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
    if ($null -ne $localConnectionInfo) {
        $script:VmSshConnectionCache[$cacheKey] = $localConnectionInfo
        return $localConnectionInfo
    }

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

    $connectionInfo = [PSCustomObject]@{
        MachineId = $machineId
        HostName = if ($values.ContainsKey('hostname')) { [string]$values['hostname'][0] } else { '127.0.0.1' }
        Port = if ($values.ContainsKey('port')) { [int]$values['port'][0] } else { 22 }
        User = if ($values.ContainsKey('user')) { [string]$values['user'][0] } else { 'vagrant' }
        IdentityFiles = if ($values.ContainsKey('identityfile')) { @($values['identityfile']) } else { @(Get-DefaultVagrantIdentityFiles) }
        ConfigLines = $configLines
    }

    $script:VmSshConnectionCache[$cacheKey] = $connectionInfo
    return $connectionInfo
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
    $standardPaths = @(
        (Join-Path $env:SystemRoot 'System32\OpenSSH\ssh.exe'),
        'C:\Windows\System32\OpenSSH\ssh.exe',
        'C:\Program Files\Git\usr\bin\ssh.exe',
        'C:\Program Files\Git\bin\ssh.exe',
        'C:\Program Files\Vagrant\embedded\usr\bin\ssh.exe'
    )

    foreach ($path in $standardPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path -PathType Leaf)) {
            return $path
        }
    }

    $candidate = Get-Command ssh.exe -ErrorAction SilentlyContinue
    if ($null -ne $candidate -and -not [string]::IsNullOrWhiteSpace([string]$candidate.Source)) {
        return $candidate.Source
    }

    throw 'Unable to locate ssh.exe on this host.'
}

function Get-ScpExecutablePath {
    param(
        [string]$SshPath = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($SshPath)) {
        $sibling = Join-Path (Split-Path -Parent $SshPath) 'scp.exe'
        if (Test-Path $sibling -PathType Leaf) {
            return $sibling
        }
    }

    $candidate = Get-Command scp.exe -ErrorAction SilentlyContinue
    if ($null -ne $candidate -and -not [string]::IsNullOrWhiteSpace([string]$candidate.Source)) {
        return $candidate.Source
    }

    $standardPaths = @(
        'C:\Program Files\Vagrant\embedded\usr\bin\scp.exe',
        (Join-Path $env:SystemRoot 'System32\OpenSSH\scp.exe'),
        'C:\Windows\System32\OpenSSH\scp.exe',
        'C:\Program Files\Git\usr\bin\scp.exe',
        'C:\Program Files\Git\bin\scp.exe'
    )

    foreach ($path in $standardPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path -PathType Leaf)) {
            return $path
        }
    }

    throw 'Unable to locate scp.exe on this host.'
}

function ConvertTo-ScpArgumentList {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$SshArgumentList,
        [Parameter(Mandatory = $true)]
        [string]$LocalPath,
        [Parameter(Mandatory = $true)]
        [string]$RemotePath
    )

    if ($SshArgumentList.Count -eq 0) {
        throw 'Cannot build scp arguments from an empty SSH argument list.'
    }

    $target = [string]$SshArgumentList[-1]
    $scpArguments = @()
    for ($index = 0; $index -lt ($SshArgumentList.Count - 1); $index++) {
        $argument = [string]$SshArgumentList[$index]
        if ($argument -eq '-p' -and $index + 1 -lt ($SshArgumentList.Count - 1)) {
            $scpArguments += '-P'
            $scpArguments += [string]$SshArgumentList[$index + 1]
            $index++
            continue
        }

        $scpArguments += $argument
    }

    return @($scpArguments + @($LocalPath, ('{0}:{1}' -f $target, $RemotePath)))
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
            try {
                $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $acl = New-Object System.Security.AccessControl.FileSecurity
                $acl.SetOwner($identity.User)
                $acl.SetAccessRuleProtection($true, $false)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $identity.User,
                    [System.Security.AccessControl.FileSystemRights]::FullControl,
                    [System.Security.AccessControl.AccessControlType]::Allow
                )
                $acl.AddAccessRule($rule)
                [System.IO.File]::SetAccessControl($tempPath, $acl)
            }
            catch {
                $grantTarget = if (-not [string]::IsNullOrWhiteSpace([string]$env:USERNAME)) { "{0}:F" -f $env:USERNAME } else { '{0}:F' -f [System.Environment]::UserName }
                $null = & icacls.exe $tempPath '/inheritance:r' '/grant:r' $grantTarget
            }
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
    $keySources = @(
        $connectionInfo.IdentityFiles |
            Where-Object { Test-Path $_ -PathType Leaf } |
            Select-Object -Unique
    )

    if ($keySources.Count -eq 0) {
        throw "No SSH identity file was found for $MachineName."
    }

    $temporaryKeyPaths = @(
        $keySources | ForEach-Object {
            New-SshSessionKeyFile -SourcePath ([string]$_) -MachineName $MachineName
        }
    )
    $argumentList = @(
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'LogLevel=ERROR',
        '-o', 'IdentitiesOnly=yes',
        '-o', 'PreferredAuthentications=publickey',
        '-o', 'PasswordAuthentication=no',
        '-o', 'KbdInteractiveAuthentication=no',
        '-o', 'NumberOfPasswordPrompts=0',
        '-o', 'PubkeyAcceptedKeyTypes=+ssh-rsa',
        '-o', 'HostKeyAlgorithms=+ssh-rsa'
    )
    foreach ($temporaryKeyPath in $temporaryKeyPaths) {
        $argumentList += @('-i', $temporaryKeyPath)
    }
    $argumentList += @('-p', ([string]$connectionInfo.Port))

    if ($BatchMode) {
        $argumentList += @(
            '-o', 'BatchMode=yes',
            '-o', 'ConnectTimeout=5',
            '-o', 'ConnectionAttempts=1',
            '-o', 'ServerAliveInterval=3',
            '-o', 'ServerAliveCountMax=1'
        )
    }

    $argumentList += ("{0}@{1}" -f $connectionInfo.User, $connectionInfo.HostName)

    return [PSCustomObject]@{
        SshPath = $sshPath
        ArgumentList = $argumentList
        TemporaryKeyPath = @($temporaryKeyPaths | Select-Object -First 1)
        TemporaryKeyPaths = @($temporaryKeyPaths)
    }
}

function Remove-VmDirectSshLaunchSpec {
    param(
        [object]$LaunchSpec
    )

    if ($null -eq $LaunchSpec) {
        return
    }

    $paths = @()
    if ($LaunchSpec.PSObject.Properties.Match('TemporaryKeyPaths').Count -gt 0) {
        $paths += @($LaunchSpec.TemporaryKeyPaths)
    }
    elseif ($LaunchSpec.PSObject.Properties.Match('TemporaryKeyPath').Count -gt 0) {
        $paths += @($LaunchSpec.TemporaryKeyPath)
    }

    foreach ($path in @($paths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)) {
        Remove-Item -Path ([string]$path) -Force -ErrorAction SilentlyContinue
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
        $cleanupCommands = @($launchSpec.TemporaryKeyPaths | ForEach-Object {
            'Remove-Item -Path {0} -Force -ErrorAction SilentlyContinue' -f (ConvertTo-PowerShellSingleQuotedString -Value ([string]$_))
        })
        $launchScript = @(
            ('$sshArgs = @({0})' -f $sshArgs),
            ('& {0} @sshArgs' -f (ConvertTo-PowerShellSingleQuotedString -Value $launchSpec.SshPath)),
            ('$code = $LASTEXITCODE')
        ) + $cleanupCommands + @(
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
        Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
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

function ConvertTo-BashDoubleQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    $escaped = $Value.Replace('\', '\\').Replace('"', '\"').Replace('$', '\$').Replace('`', '\`')
    return '"{0}"' -f $escaped
}

function ConvertTo-BashEnvironmentArgumentList {
    param(
        [hashtable]$Environment = @{}
    )

    $argumentList = @()
    foreach ($key in @($Environment.Keys | Sort-Object)) {
        $name = [string]$key
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            throw "Invalid shell environment variable name '$name'."
        }

        $argumentList += ('{0}={1}' -f $name, (ConvertTo-BashDoubleQuotedString -Value ([string]$Environment[$key])))
    }

    return $argumentList
}

function New-DirectSshBashScriptCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptContent,
        [hashtable]$Environment = @{}
    )

    $encodedScript = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ScriptContent))
    $environmentArguments = @(ConvertTo-BashEnvironmentArgumentList -Environment $Environment)
    $sudoCommand = if ($environmentArguments.Count -gt 0) {
        'sudo -n env {0} /bin/bash' -f ($environmentArguments -join ' ')
    }
    else {
        'sudo -n /bin/bash'
    }

    return 'tmpfile=$(mktemp /tmp/rhcsa-ssh.XXXXXX) || exit 125; printf %s {0} | base64 -d > "$tmpfile"; {1} "$tmpfile"; rc=$?; rm -f "$tmpfile"; printf "\n__RHCSA_DIRECT_SSH_EXIT__:%s\n" "$rc"; exit 0' -f (ConvertTo-BashDoubleQuotedString -Value $encodedScript), $sudoCommand
}

function ConvertFrom-DirectSshBashScriptResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Result
    )

    $exitCode = $null
    $stdout = @()
    foreach ($line in @($Result.StdOut)) {
        if ([string]$line -match '^__RHCSA_DIRECT_SSH_EXIT__:(\d+)$') {
            $exitCode = [int]$matches[1]
            continue
        }

        $stdout += $line
    }

    $stderr = @()
    foreach ($line in @($Result.StdErr)) {
        if ([string]$line -match '^__RHCSA_DIRECT_SSH_EXIT__:(\d+)$') {
            $exitCode = [int]$matches[1]
            continue
        }

        $stderr += $line
    }

    if ($null -eq $exitCode) {
        $exitCode = if ([int]$Result.ExitCode -ne 0) { [int]$Result.ExitCode } else { 124 }
        $stderr += 'Direct SSH command did not return the RHCSA exit marker.'
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        StdOut = $stdout
        StdErr = $stderr
    }
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

    $vmId = Get-OptionalVagrantMachineId -MachineName $MachineName -ProjectRoot $ProjectRoot
    if (-not [string]::IsNullOrWhiteSpace($vmId)) {
        $vboxManage = Get-VBoxManagePath
        $vboxState = Get-VBoxMachineState -VmId $vmId -VBoxManagePath $vboxManage
        if ($vboxState -and [string]$vboxState -in @('poweroff', 'saved', 'aborted')) {
            Invoke-ExternalCommand -FilePath $vboxManage -ArgumentList @('startvm', $vmId, '--type', 'headless') -FailureMessage "Failed to start $MachineName before SSH connectivity validation." -SuppressOutput
            Clear-VmSshConnectionCache -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
        }
    }

    $machineStatus = @(Get-VagrantMachineStatus -ProjectRoot $ProjectRoot | Where-Object { [string]$_.Name -eq $MachineName } | Select-Object -First 1)
    $currentVmState = if (-not [string]::IsNullOrWhiteSpace($vmId)) { Get-VBoxMachineState -VmId $vmId -VBoxManagePath (Get-VBoxManagePath) } else { $null }
    if ($machineStatus.Count -gt 0 -and [string]$currentVmState -ne 'running') {
        $stateHuman = [string]$machineStatus[0].StateHuman
        $upTimeoutSeconds = Get-VagrantUpTimeoutSeconds -ProjectRoot $ProjectRoot
        switch ($stateHuman) {
            'not created' {
                throw "$MachineName is not created. Run .\RHCSA.ps1 up first."
            }
            'poweroff' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed." -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
            }
            'saved' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed." -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
            }
            'paused' {
                Invoke-VagrantCommand -ArgumentList @('up', $MachineName, '--no-provision', '--no-color') -FailureMessage "'vagrant up $MachineName --no-provision' failed." -TimeoutSeconds $upTimeoutSeconds -SuppressOutput
            }
        }
    }

    $readinessCommand = Get-VmSshReadinessCommand -ProjectRoot $ProjectRoot
    $readinessTimeoutSeconds = 15
    $lastOutput = ''
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $connectionInfo = $null
        try {
            $connectionInfo = Get-VmSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
        }
        catch {
            $lastOutput = $_.Exception.Message
        }

        if (
            $null -eq $connectionInfo -or
            -not (Test-SshBannerReady -HostName ([string]$connectionInfo.HostName) -Port ([int]$connectionInfo.Port) -TimeoutMilliseconds 3000)
        ) {
            $lastOutput = if ($null -eq $connectionInfo) { $lastOutput } else { "SSH banner is not ready on $($connectionInfo.HostName):$($connectionInfo.Port)." }
            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            $suffix = if ([string]::IsNullOrWhiteSpace($lastOutput)) { '' } else { " Last SSH output: $(ConvertTo-CompactWorkflowMessage -Message $lastOutput)" }
            throw "Failed to validate SSH connectivity for $MachineName.$suffix"
        }

        $launchSpec = $null
        try {
            $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
            $result = Invoke-ExternalCapture -FilePath $launchSpec.SshPath -ArgumentList ($launchSpec.ArgumentList + @($readinessCommand)) -TimeoutSeconds $readinessTimeoutSeconds
        }
        finally {
            Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
        }

        if ($result.ExitCode -eq 0 -and ((@($result.StdOut) -join "`n") -match '__RHCSA_SSH_READY__')) {
            Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
            return
        }

        $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
        $lastOutput = $combinedOutput
        $isRetryable = $combinedOutput -match 'Permission denied|Connection refused|Connection reset|timed out|Connection timed out|Connection closed|No route to host|Broken pipe|kex_exchange_identification|banner exchange'
        if ($attempt -lt $RetryCount -and $isRetryable) {
            Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
            continue
        }

        $suffix = if ([string]::IsNullOrWhiteSpace($lastOutput)) { '' } else { " Last SSH output: $(ConvertTo-CompactWorkflowMessage -Message $lastOutput)" }
        throw "Failed to validate SSH connectivity for $MachineName.$suffix"
    }
}

function Test-VmBatchSshReady {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$TimeoutSeconds = 15
    )

    $launchSpec = $null
    try {
        $connectionInfo = Get-VmSshConnectionInfo -MachineName $MachineName -ProjectRoot $ProjectRoot
        if (-not (Test-SshBannerReady -HostName ([string]$connectionInfo.HostName) -Port ([int]$connectionInfo.Port) -TimeoutMilliseconds 3000)) {
            return $false
        }

        $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
        $readinessCommand = Get-VmSshReadinessCommand -ProjectRoot $ProjectRoot
        $result = Invoke-ExternalCapture -FilePath $launchSpec.SshPath -ArgumentList ($launchSpec.ArgumentList + @($readinessCommand)) -TimeoutSeconds $TimeoutSeconds
        if ($result.ExitCode -eq 0 -and ((@($result.StdOut) -join "`n") -match '__RHCSA_SSH_READY__')) {
            Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
            return $true
        }
    }
    catch {
        return $false
    }
    finally {
        Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
    }

    return $false
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
        [int]$RetryDelaySeconds = 5,
        [switch]$SkipConnectivityCheck,
        [switch]$SkipVagrantFallback
    )

    try {
        if (-not $SkipConnectivityCheck.IsPresent) {
            Test-VagrantSshConnectivity -MachineName $MachineName -ProjectRoot $ProjectRoot
        }

        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $launchSpec = $null
            try {
                $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
                $remoteCommand = New-DirectSshBashScriptCommand -ScriptContent $Command
                $result = Invoke-ExternalCapture `
                    -FilePath $launchSpec.SshPath `
                    -ArgumentList ($launchSpec.ArgumentList + @($remoteCommand)) `
                    -TimeoutSeconds 60
                $result = ConvertFrom-DirectSshBashScriptResult -Result $result
            }
            finally {
                Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
            }

            $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
            $canRetry = $attempt -le $RetryCount -and $combinedOutput -match 'Permission denied|Connection refused|Connection reset|timed out|Connection closed|No route to host|Broken pipe|kex_exchange_identification|Direct SSH command did not return the RHCSA exit marker'
            if ($canRetry) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            if ($result.ExitCode -eq 0) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
            }
            return $result
        }
    }
    catch {
        if ($SkipVagrantFallback) {
            throw
        }
        $fallbackReason = ConvertTo-CompactWorkflowMessage -Message $_.Exception.Message
        Write-WorkflowStatus -Area 'check' -Message "Falling back to Vagrant provision transport for $MachineName checks: $fallbackReason"
    }

    $vagrantCommand = Get-VagrantCommandSpec
    $provisionerName = Get-LabCheckProvisionerName -MachineName $MachineName

    Clear-LabCheckScriptState -ProjectRoot $ProjectRoot
    Write-LabCheckScript -MachineName $MachineName -Command $Command -ProjectRoot $ProjectRoot | Out-Null

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $result = Invoke-VagrantExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + @('provision', $MachineName, '--provision-with', $provisionerName, '--no-color')) -TimeoutSeconds 180
            if ($result.ExitCode -eq 0 -and -not (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
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

function Invoke-VagrantVmScript {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('server', 'client')]
        [string]$MachineName,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [AllowEmptyString()]
        [string]$ProvisionerName,
        [string]$ProjectRoot = (Get-ProjectRoot),
        [int]$RetryCount = 2,
        [int]$RetryDelaySeconds = 5,
        [int]$TimeoutSeconds = 120,
        [string]$RetryArea = 'scenario',
        [string]$RetryMessage = 'Retrying the VM overlay after a transient SSH/provider failure',
        [hashtable]$Environment = @{},
        [switch]$SkipConnectivityCheck,
        [switch]$SkipVagrantFallback
    )

    $scriptContent = Get-Content -Path $ScriptPath -Raw -Encoding UTF8

    try {
        if (-not $SkipConnectivityCheck.IsPresent) {
            Test-VagrantSshConnectivity -MachineName $MachineName -ProjectRoot $ProjectRoot
        }

        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $launchSpec = $null
            $localScriptPath = $null
            try {
                $launchSpec = Get-VmDirectSshLaunchSpec -MachineName $MachineName -ProjectRoot $ProjectRoot -BatchMode
                $scriptId = [System.Guid]::NewGuid().ToString('N')
                $localScriptPath = Join-Path ([System.IO.Path]::GetTempPath()) ("rhcsa-{0}-{1}.sh" -f $MachineName, $scriptId)
                $remoteScriptPath = "/tmp/rhcsa-${MachineName}-${scriptId}.sh"
                Set-Utf8NoBomFile -Path $localScriptPath -Content $scriptContent

                $scpPath = Get-ScpExecutablePath -SshPath $launchSpec.SshPath
                $scpArguments = ConvertTo-ScpArgumentList -SshArgumentList $launchSpec.ArgumentList -LocalPath $localScriptPath -RemotePath $remoteScriptPath
                $copyResult = Invoke-ExternalCapture -FilePath $scpPath -ArgumentList $scpArguments -TimeoutSeconds 60
                if ([int]$copyResult.ExitCode -ne 0) {
                    $result = [PSCustomObject]@{
                        ExitCode = [int]$copyResult.ExitCode
                        StdOut = @($copyResult.StdOut)
                        StdErr = @($copyResult.StdErr)
                    }
                }
                else {
                    $environmentArguments = @(ConvertTo-BashEnvironmentArgumentList -Environment $Environment)
                    $sudoCommand = if ($environmentArguments.Count -gt 0) {
                        'sudo -n env {0} /bin/bash' -f ($environmentArguments -join ' ')
                    }
                    else {
                        'sudo -n /bin/bash'
                    }
                    $quotedRemoteScriptPath = ConvertTo-BashDoubleQuotedString -Value $remoteScriptPath
                    $remoteCommand = '{0} {1}; rc=$?; rm -f {1}; printf "\n__RHCSA_DIRECT_SSH_EXIT__:%s\n" "$rc"; exit 0' -f $sudoCommand, $quotedRemoteScriptPath
                    $result = Invoke-ExternalCapture `
                        -FilePath $launchSpec.SshPath `
                        -ArgumentList ($launchSpec.ArgumentList + @($remoteCommand)) `
                        -TimeoutSeconds $TimeoutSeconds
                    $result = ConvertFrom-DirectSshBashScriptResult -Result $result
                }
            }
            finally {
                if (-not [string]::IsNullOrWhiteSpace([string]$localScriptPath)) {
                    Remove-Item -Path $localScriptPath -Force -ErrorAction SilentlyContinue
                }
                Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
            }

            $combinedOutput = ((@($result.StdOut) + @($result.StdErr)) -join "`n")
            $canRetry = $attempt -le $RetryCount -and $combinedOutput -match 'Permission denied|Connection refused|Connection reset|timed out|Connection closed|No route to host|Broken pipe|kex_exchange_identification|Direct SSH command did not return the RHCSA exit marker'
            if ($canRetry) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            if ($result.ExitCode -eq 0) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                return $result
            }

            if ($SkipVagrantFallback) {
                Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            }
            $failureTail = ((@($result.StdErr) + @($result.StdOut)) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Last 8) -join ' | '
            if (-not [string]::IsNullOrWhiteSpace($failureTail)) {
                throw "Direct SSH execution failed for $MachineName script '$ScriptPath'. Last output: $failureTail"
            }
            throw "Direct SSH execution failed for $MachineName script '$ScriptPath'."
        }
    }
    catch {
        if ($SkipVagrantFallback) {
            throw
        }
        $fallbackReason = ConvertTo-CompactWorkflowMessage -Message $_.Exception.Message
        Write-WorkflowStatus -Area $RetryArea -Message "Falling back to Vagrant provision transport for $MachineName overlay: $fallbackReason"
    }

    $vagrantCommand = Get-VagrantCommandSpec

    Push-Location $ProjectRoot
    try {
        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            $fallbackArguments = if ([string]::IsNullOrWhiteSpace($ProvisionerName)) {
                @('provision', $MachineName, '--no-color')
            }
            else {
                @('provision', $MachineName, '--provision-with', $ProvisionerName, '--no-color')
            }

            $result = Invoke-VagrantExternalCapture -FilePath $vagrantCommand.FilePath -ArgumentList @($vagrantCommand.PrefixArgumentList + $fallbackArguments) -TimeoutSeconds $TimeoutSeconds
            if ($result.ExitCode -eq 0 -and -not (Test-VagrantCommandReportedFailure -StdOut $result.StdOut -StdErr $result.StdErr)) {
                Remove-VagrantActionMarkers -ProjectRoot $ProjectRoot -MachineNames @($MachineName)
                return $result
            }

            $canRetry = $attempt -le $RetryCount -and (Test-TransientVagrantFailure -StdOut $result.StdOut -StdErr $result.StdErr)
            if ($canRetry) {
                Write-WorkflowStatus -Area $RetryArea -Message $RetryMessage
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
                continue
            }

            Write-FailureTranscript -StdOut $result.StdOut -StdErr $result.StdErr | Out-Null
            throw "Failed to apply $MachineName overlay via Vagrant provision transport."
        }
    }
    finally {
        Pop-Location
    }
}
