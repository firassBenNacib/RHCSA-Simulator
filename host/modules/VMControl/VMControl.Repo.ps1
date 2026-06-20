# Dot-sourced by VMControl.psm1. Keep functions in this file internal unless exported by VMControl.psd1.

function Get-RhcsaOfflineIsoPath {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [Alias('Profile')]
        [string]$ProjectProfile = (Get-ProjectProfile -ProjectRoot $ProjectRoot),
        [switch]$Required
    )

    $profileKey = ([string]$ProjectProfile).ToLowerInvariant()
    if ($profileKey -eq 'rhcsa10') {
        $profileKey = 'rhel10'
    }
    elseif ($profileKey -eq 'rhcsa9') {
        $profileKey = 'rhel9'
    }

    $major = if ($profileKey -eq 'rhel10') { '10' } else { '9' }
    $defaultIsoName = if ($major -eq '10') { 'rhel-10.2-x86_64-dvd.iso' } else { 'rhel-9.8-x86_64-dvd.iso' }
    $pattern = "rhel-$major.*-x86_64-dvd.iso"

    $override = [string]$env:RHCSA_ISO
    if (-not [string]::IsNullOrWhiteSpace($override)) {
        $overridePath = if ([System.IO.Path]::IsPathRooted($override)) {
            $override
        }
        else {
            Join-Path $ProjectRoot $override
        }

        if (Test-Path $overridePath -PathType Leaf) {
            return (Resolve-Path -LiteralPath $overridePath).ProviderPath
        }

        if ($Required) {
            throw "Missing offline ISO: $overridePath"
        }

        return $null
    }

    $match = Get-ChildItem -Path $ProjectRoot -Filter $pattern -File -ErrorAction SilentlyContinue |
        Sort-Object -Property @{
            Expression = {
                if ($_.Name -match '^rhel-(\d+(?:\.\d+)+)-x86_64-dvd\.iso$') {
                    [version]$Matches[1]
                }
                else {
                    [version]'0.0'
                }
            }
            Descending = $true
        } |
        Select-Object -First 1

    if ($null -ne $match) {
        return $match.FullName
    }

    if ($Required) {
        throw "Missing RHEL $major DVD ISO. Download the x86_64 DVD ISO from https://developers.redhat.com/products/rhel/download#downloadsbyrelease, place $defaultIsoName or any $pattern in $ProjectRoot, or set RHCSA_ISO to a filename or full path."
    }

    return $null
}

function Get-RhcsaRepoCachePath {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [Alias('Profile')]
        [string]$ProjectProfile = (Get-ProjectProfile -ProjectRoot $ProjectRoot)
    )

    $profile = ConvertTo-ProjectProfile -Profile $ProjectProfile
    return (Join-Path (Join-Path $ProjectRoot '.rhcsa-repo') $profile)
}

function Test-RhcsaRepoCacheReady {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [Alias('Profile')]
        [string]$ProjectProfile = (Get-ProjectProfile -ProjectRoot $ProjectRoot)
    )

    $cachePath = Get-RhcsaRepoCachePath -ProjectRoot $ProjectRoot -Profile $ProjectProfile
    return (
        (Test-Path (Join-Path $cachePath 'BaseOS/repodata/repomd.xml') -PathType Leaf) -and
        (Test-Path (Join-Path $cachePath 'AppStream/repodata/repomd.xml') -PathType Leaf)
    )
}

function Assert-RhcsaOfflineSourceReady {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot),
        [Alias('Profile')]
        [string]$ProjectProfile = (Get-ProjectProfile -ProjectRoot $ProjectRoot)
    )

    if (Test-RhcsaRepoCacheReady -ProjectRoot $ProjectRoot -Profile $ProjectProfile) {
        return
    }

    Get-RhcsaOfflineIsoPath -ProjectRoot $ProjectRoot -Profile $ProjectProfile -Required | Out-Null
}

function Assert-RhcsaCachePathSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $cacheRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot '.rhcsa-repo'))
    $target = [System.IO.Path]::GetFullPath($Path)
    $cacheRootWithSeparator = $cacheRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $target.StartsWith($cacheRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify path outside .rhcsa-repo: $target"
    }
}

function Get-RhcsaIsoMountRoot {
    param(
        [Parameter(Mandatory = $true)]
        [object]$DiskImage
    )

    $deadline = (Get-Date).AddSeconds(30)
    do {
        $volume = $DiskImage | Get-Volume -ErrorAction SilentlyContinue | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.DriveLetter) } | Select-Object -First 1
        if ($null -ne $volume) {
            return ('{0}:\' -f $volume.DriveLetter)
        }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    throw 'The ISO mounted, but no drive letter was assigned.'
}

function Import-RhcsaOfflineIso {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IsoPath,
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $resolvedSource = Resolve-Path -LiteralPath $IsoPath -ErrorAction Stop
    $sourcePath = $resolvedSource.ProviderPath
    if (-not (Test-Path $sourcePath -PathType Leaf)) {
        throw "ISO path is not a file: $IsoPath"
    }

    $sourceItem = Get-Item -LiteralPath $sourcePath
    if ($sourceItem.Name -notmatch '^rhel-(9|10)(?:\.\d+)*-x86_64-dvd\.iso$') {
        throw "Unsupported ISO filename '$($sourceItem.Name)'. Use a RHEL 9 or RHEL 10 x86_64 DVD ISO named like rhel-10.2-x86_64-dvd.iso."
    }

    $major = $Matches[1]
    $profile = if ($major -eq '10') { 'rhel10' } else { 'rhel9' }
    $cachePath = Get-RhcsaRepoCachePath -ProjectRoot $ProjectRoot -Profile $profile
    $manifestPath = Join-Path $cachePath 'rhcsa-repo-cache.json'
    $status = 'cached'
    if (Test-RhcsaRepoCacheReady -ProjectRoot $ProjectRoot -Profile $profile) {
        $cachedSourceIso = ''
        if (Test-Path $manifestPath -PathType Leaf) {
            try {
                $cachedSourceIso = [string](Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json).source_iso
            }
            catch {
                $cachedSourceIso = ''
            }
        }

        if ($cachedSourceIso -eq $sourceItem.Name) {
            return [PSCustomObject]@{
                Status = 'already-cached'
                Source = [System.IO.Path]::GetFullPath($sourcePath)
                Destination = [System.IO.Path]::GetFullPath($cachePath)
                Profile = if ($major -eq '10') { 'RHEL10' } else { 'RHEL9' }
                Pattern = "rhel-$major.*-x86_64-dvd.iso"
                CacheReady = $true
            }
        }

        $status = 'refreshed'
    }

    $mountCommand = Get-Command Mount-DiskImage -ErrorAction SilentlyContinue
    $dismountCommand = Get-Command Dismount-DiskImage -ErrorAction SilentlyContinue
    if ($null -eq $mountCommand -or $null -eq $dismountCommand) {
        throw 'Repo cache import requires Windows Mount-DiskImage/Dismount-DiskImage support.'
    }

    $cacheRoot = Join-Path $ProjectRoot '.rhcsa-repo'
    $tempPath = Join-Path $cacheRoot ('.import-{0}-{1}' -f $profile, [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

    $mountedImage = $null
    try {
        $mountedImage = Mount-DiskImage -ImagePath $sourcePath -StorageType ISO -PassThru
        $mountRoot = Get-RhcsaIsoMountRoot -DiskImage $mountedImage
        foreach ($repoName in @('BaseOS', 'AppStream')) {
            $repoSource = Join-Path $mountRoot $repoName
            $repoMetadata = Join-Path $repoSource 'repodata/repomd.xml'
            if (-not (Test-Path $repoMetadata -PathType Leaf)) {
                throw "ISO is missing $repoName repository metadata."
            }
            Copy-Item -LiteralPath $repoSource -Destination $tempPath -Recurse -Force
        }

        $manifest = [PSCustomObject]@{
            profile = $profile
            source_iso = $sourceItem.Name
            imported_at = (Get-Date).ToUniversalTime().ToString('o')
        } | ConvertTo-Json -Depth 3
        Set-Utf8NoBomFile -Path (Join-Path $tempPath 'rhcsa-repo-cache.json') -Content ($manifest + [Environment]::NewLine)

        if (-not (Test-Path (Join-Path $tempPath 'BaseOS/repodata/repomd.xml') -PathType Leaf) -or -not (Test-Path (Join-Path $tempPath 'AppStream/repodata/repomd.xml') -PathType Leaf)) {
            throw 'Imported cache is incomplete.'
        }

        Assert-RhcsaCachePathSafe -ProjectRoot $ProjectRoot -Path $tempPath
        if (Test-Path $cachePath) {
            Assert-RhcsaCachePathSafe -ProjectRoot $ProjectRoot -Path $cachePath
            Remove-Item -LiteralPath $cachePath -Recurse -Force
        }
        Move-Item -LiteralPath $tempPath -Destination $cachePath
    }
    finally {
        if ($null -ne $mountedImage) {
            Dismount-DiskImage -ImagePath $sourcePath -ErrorAction SilentlyContinue | Out-Null
        }
        if (Test-Path $tempPath) {
            Assert-RhcsaCachePathSafe -ProjectRoot $ProjectRoot -Path $tempPath
            Remove-Item -LiteralPath $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    return [PSCustomObject]@{
        Status = $status
        Source = [System.IO.Path]::GetFullPath($sourcePath)
        Destination = [System.IO.Path]::GetFullPath($cachePath)
        Profile = if ($major -eq '10') { 'RHEL10' } else { 'RHEL9' }
        Pattern = "rhel-$major.*-x86_64-dvd.iso"
        CacheReady = Test-RhcsaRepoCacheReady -ProjectRoot $ProjectRoot -Profile $profile
    }
}

function Copy-RhcsaRepoCacheToServer {
    param(
        [string]$ProjectRoot = (Get-ProjectRoot)
    )

    $projectProfile = Get-ProjectProfile -ProjectRoot $ProjectRoot
    if (-not (Test-RhcsaRepoCacheReady -ProjectRoot $ProjectRoot -Profile $projectProfile)) {
        return $false
    }

    $cachePath = Get-RhcsaRepoCachePath -ProjectRoot $ProjectRoot -Profile $projectProfile
    $baseOsPath = Join-Path $cachePath 'BaseOS'
    $appStreamPath = Join-Path $cachePath 'AppStream'
    $manifestPath = Join-Path $cachePath 'rhcsa-repo-cache.json'
    $remoteStage = '/tmp/rhcsa-repo-cache-upload'
    $localManifest = ''
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        $localManifest = (Get-Content -LiteralPath $manifestPath -Raw).Trim()
    }

    if (-not [string]::IsNullOrWhiteSpace($localManifest)) {
        $remoteManifestCheck = @'
set -euo pipefail
test -f /var/www/html/repo/BaseOS/repodata/repomd.xml
test -f /var/www/html/repo/AppStream/repodata/repomd.xml
test -f /var/www/html/repo/rhcsa-repo-cache.json
cat /var/www/html/repo/rhcsa-repo-cache.json
'@
        try {
            $remoteManifestResult = Invoke-VagrantVmShellCommandCapture `
                -MachineName 'server' `
                -ProjectRoot $ProjectRoot `
                -Command $remoteManifestCheck `
                -RetryCount 0 `
                -SkipConnectivityCheck `
                -SkipVagrantFallback
            $remoteManifest = ((@($remoteManifestResult.StdOut) -join [Environment]::NewLine).Trim())
            if ([int]$remoteManifestResult.ExitCode -eq 0 -and $remoteManifest -eq $localManifest) {
                return $true
            }
        }
        catch {
            $null = $_
        }
    }

    $prepareResult = Invoke-VagrantVmShellCommandCapture `
        -MachineName 'server' `
        -ProjectRoot $ProjectRoot `
        -Command "rm -rf $remoteStage && mkdir -p $remoteStage" `
        -RetryCount 1 `
        -RetryDelaySeconds 3 `
        -SkipConnectivityCheck `
        -SkipVagrantFallback
    if ([int]$prepareResult.ExitCode -ne 0) {
        throw 'Failed to prepare the server repo cache upload directory.'
    }

    $launchSpec = $null
    try {
        $launchSpec = Get-VmDirectSshLaunchSpec -MachineName 'server' -ProjectRoot $ProjectRoot -BatchMode
        $scpPath = Get-ScpExecutablePath -SshPath $launchSpec.SshPath
        foreach ($localPath in @($baseOsPath, $appStreamPath)) {
            $scpArguments = @('-r') + @(ConvertTo-ScpArgumentList -SshArgumentList $launchSpec.ArgumentList -LocalPath $localPath -RemotePath ($remoteStage + '/'))
            $copyResult = Invoke-ExternalCapture -FilePath $scpPath -ArgumentList $scpArguments -TimeoutSeconds 3600
            if ([int]$copyResult.ExitCode -ne 0) {
                Write-FailureTranscript -StdOut $copyResult.StdOut -StdErr $copyResult.StdErr | Out-Null
                throw "Failed to upload repo cache directory '$localPath' to server."
            }
        }
    }
    finally {
        Remove-VmDirectSshLaunchSpec -LaunchSpec $launchSpec
    }

    $installCommand = @'
set -euo pipefail
test -f /tmp/rhcsa-repo-cache-upload/BaseOS/repodata/repomd.xml
test -f /tmp/rhcsa-repo-cache-upload/AppStream/repodata/repomd.xml
sudo rm -rf /var/www/html/repo
sudo mkdir -p /var/www/html
sudo mv /tmp/rhcsa-repo-cache-upload /var/www/html/repo
sudo chown -R root:root /var/www/html/repo
sudo restorecon -RF /var/www/html/repo >/dev/null 2>&1 || true
'@
    $installResult = Invoke-VagrantVmShellCommandCapture `
        -MachineName 'server' `
        -ProjectRoot $ProjectRoot `
        -Command $installCommand `
        -RetryCount 0 `
        -SkipConnectivityCheck `
        -SkipVagrantFallback
    if ([int]$installResult.ExitCode -ne 0) {
        Write-FailureTranscript -StdOut $installResult.StdOut -StdErr $installResult.StdErr | Out-Null
        throw 'Failed to install the uploaded repo cache on server.'
    }

    return $true
}

