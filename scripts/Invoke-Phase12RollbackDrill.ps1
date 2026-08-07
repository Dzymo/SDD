[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ManifestPath,
    [switch]$VerifyOnly
)

Set-StrictMode -Version Latest

function Get-ManifestValue {
    param(
        [object]$Entry,
        [string]$Name
    )

    $property = @($Entry.PSObject.Properties | Where-Object { $_.Name -ieq $Name }) | Select-Object -First 1
    if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        throw "Rollback manifest entry is missing $Name."
    }

    return [string]$property.Value
}

function Get-FileHashOrAbsent {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 'ABSENT'
    }

    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha256.ComputeHash($stream) | ForEach-Object { $_.ToString('X2') }) -join '')
    }
    finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
}

function Assert-FrameworkTarget {
    param(
        [string]$Target,
        [string]$OpenCodeRoot
    )

    $fullTarget = [System.IO.Path]::GetFullPath($Target)
    $rootWithSeparator = $OpenCodeRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullTarget.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Rollback target is outside the OpenCode configuration root: $fullTarget"
    }

    return $fullTarget
}

$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match 'openchamber|cpa|opencode'
})
if ($running.Count -gt 0) {
    $processes = $running | ForEach-Object { "$($_.ProcessName) (PID $($_.Id))" }
    throw "Close OpenChamber and CPA GUI before a rollback drill. Running: $($processes -join ', ')"
}

$manifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifestDirectory = Split-Path -Parent $manifestPath
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -ErrorAction Stop
if ($manifest -is [System.Array]) {
    $entries = @($manifest)
}
elseif ($null -ne $manifest.PSObject.Properties['entries']) {
    $entries = @($manifest.entries)
}
elseif ($null -ne $manifest.PSObject.Properties['target']) {
    $entries = @($manifest)
}
else {
    throw "Unsupported rollback manifest shape: $manifestPath"
}
if ($entries.Count -eq 0) {
    throw "Rollback manifest has no target entries: $manifestPath"
}

$openCodeRoot = [System.IO.Path]::GetFullPath((Join-Path $env:USERPROFILE '.config\opencode'))
foreach ($entry in $entries) {
    $target = Assert-FrameworkTarget -Target (Get-ManifestValue -Entry $entry -Name 'Target') -OpenCodeRoot $openCodeRoot
    $beforeHash = Get-ManifestValue -Entry $entry -Name 'BeforeSha256'
    $currentHash = Get-FileHashOrAbsent -Path $target

    if ($beforeHash -eq 'ABSENT') {
        if ($VerifyOnly) {
            if ($currentHash -ne 'ABSENT') {
                throw "Rollback verification failed; target should be absent: $target"
            }
            "Rollback verified absent target: $target"
            continue
        }

        if ($currentHash -eq 'ABSENT') {
            "Rollback no-op; target is already absent: $target"
            continue
        }
        if ($PSCmdlet.ShouldProcess($target, 'remove a framework-owned target recorded as absent before apply')) {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
            if ((Get-FileHashOrAbsent -Path $target) -ne 'ABSENT') {
                throw "Rollback did not remove target recorded as absent: $target"
            }
            "Rollback restored absent state: $target"
        }
        continue
    }

    $backup = Get-ManifestValue -Entry $entry -Name 'Backup'
    $fullBackup = [System.IO.Path]::GetFullPath($backup)
    $backupRoot = $manifestDirectory.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullBackup.StartsWith($backupRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Rollback backup is outside its manifest directory: $fullBackup"
    }
    if ((Get-FileHashOrAbsent -Path $fullBackup) -ne $beforeHash) {
        throw "Rollback backup hash does not match BeforeSha256: $fullBackup"
    }

    if ($VerifyOnly) {
        if ($currentHash -ne $beforeHash) {
            throw "Rollback verification failed; target hash does not match BeforeSha256: $target"
        }
        "Rollback verified restored target: $target"
        continue
    }

    if ($PSCmdlet.ShouldProcess($target, 'restore the exact file recorded in the rollback manifest')) {
        Copy-Item -LiteralPath $fullBackup -Destination $target -Force -ErrorAction Stop
        if ((Get-FileHashOrAbsent -Path $target) -ne $beforeHash) {
            throw "Rollback target hash does not match BeforeSha256 after restore: $target"
        }
        "Rollback restored target: $target"
    }
}

if ($VerifyOnly) {
    'Phase 12 rollback verification: PASS'
}
elseif ($WhatIfPreference) {
    'Phase 12 rollback preview: PASS'
}
else {
    'Phase 12 rollback restore: PASS'
}
