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

function Assert-Sha256Value {
    param(
        [string]$Value,
        [string]$Name,
        [switch]$AllowAbsent
    )

    if ($AllowAbsent -and $Value -eq 'ABSENT') {
        return
    }
    if ($Value -notmatch '^[A-Fa-f0-9]{64}$') {
        throw "Rollback manifest $Name must be a SHA-256 value$(if ($AllowAbsent) { ' or ABSENT' }): $Value"
    }
}

function Assert-NoReparsePoint {
    param(
        [string]$Path,
        [string]$Root,
        [string]$Label
    )

    if (Test-Path -LiteralPath $Root) {
        $rootItem = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
        if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Label root is a reparse point: $Root"
        }
    }

    $rootWithSeparator = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $Path.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label is outside its approved root: $Path"
    }

    $relativePath = $Path.Substring($rootWithSeparator.Length)
    $currentPath = $Root
    foreach ($segment in @($relativePath -split '[\\/]' | Where-Object { $_ })) {
        $currentPath = Join-Path $currentPath $segment
        if (-not (Test-Path -LiteralPath $currentPath)) {
            continue
        }
        $item = Get-Item -LiteralPath $currentPath -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Label traverses a reparse point: $currentPath"
        }
    }
}

function Get-AllowedFrameworkTargets {
    param([string]$OpenCodeRoot)

    $relativeTargets = @(
        'opencode.jsonc',
        'oh-my-opencode-slim.json',
        'oh-my-opencode-slim\sdd-personal\orchestrator.md',
        'oh-my-opencode-slim\sdd-personal\explorer.md',
        'oh-my-opencode-slim\sdd-personal\librarian.md',
        'oh-my-opencode-slim\sdd-personal\fixer.md',
        'oh-my-opencode-slim\sdd-personal\oracle.md',
        'oh-my-opencode-slim\sdd-personal\designer.md',
        'oh-my-opencode-slim\sdd-personal\observer.md',
        'skills\source-first-research\SKILL.md',
        'skills\systematic-debugging\SKILL.md',
        'skills\verification-before-completion\SKILL.md',
        'skills\ui-quality\SKILL.md',
        'skills\package-and-release\SKILL.md'
    )

    $allowedTargets = @{}
    foreach ($relativeTarget in $relativeTargets) {
        $fullTarget = [System.IO.Path]::GetFullPath((Join-Path $OpenCodeRoot $relativeTarget))
        $allowedTargets[$fullTarget] = $true
    }
    return $allowedTargets
}

function Assert-FrameworkTarget {
    param(
        [string]$Target,
        [string]$OpenCodeRoot,
        [hashtable]$AllowedTargets
    )

    $fullTarget = [System.IO.Path]::GetFullPath($Target)
    if (-not $AllowedTargets.ContainsKey($fullTarget)) {
        throw "Rollback target is not a named framework-owned target: $fullTarget"
    }
    Assert-NoReparsePoint -Path $fullTarget -Root $OpenCodeRoot -Label 'Rollback target'
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
$allowedTargets = Get-AllowedFrameworkTargets -OpenCodeRoot $openCodeRoot
$seenTargets = @{}
$rollbackPlan = @()
foreach ($entry in $entries) {
    $target = Assert-FrameworkTarget -Target (Get-ManifestValue -Entry $entry -Name 'Target') -OpenCodeRoot $openCodeRoot -AllowedTargets $allowedTargets
    if ($seenTargets.ContainsKey($target)) {
        throw "Rollback manifest contains a duplicate target: $target"
    }
    $seenTargets[$target] = $true

    $beforeHash = Get-ManifestValue -Entry $entry -Name 'BeforeSha256'
    $afterHash = Get-ManifestValue -Entry $entry -Name 'AfterSha256'
    Assert-Sha256Value -Value $beforeHash -Name 'BeforeSha256' -AllowAbsent
    Assert-Sha256Value -Value $afterHash -Name 'AfterSha256'
    $currentHash = Get-FileHashOrAbsent -Path $target

    $expectedCurrentHash = if ($VerifyOnly) { $beforeHash } else { $afterHash }
    if ($currentHash -ne $expectedCurrentHash) {
        $stateName = if ($VerifyOnly) { 'BeforeSha256' } else { 'AfterSha256' }
        throw "Rollback preflight failed; target hash does not match $stateName. Target: $target. Expected: $expectedCurrentHash. Found: $currentHash."
    }

    $backup = Get-ManifestValue -Entry $entry -Name 'Backup'
    $fullBackup = 'ABSENT'
    if ($beforeHash -eq 'ABSENT') {
        if ($backup -ne 'ABSENT') {
            throw "Rollback manifest backup must be ABSENT when BeforeSha256 is ABSENT: $target"
        }
    }
    else {
        $fullBackup = [System.IO.Path]::GetFullPath($backup)
        Assert-NoReparsePoint -Path $fullBackup -Root $manifestDirectory -Label 'Rollback backup'
        if ((Get-FileHashOrAbsent -Path $fullBackup) -ne $beforeHash) {
            throw "Rollback backup hash does not match BeforeSha256: $fullBackup"
        }
    }

    $rollbackPlan += [pscustomobject]@{
        Target = $target
        Backup = $fullBackup
        BeforeSha256 = $beforeHash
        AfterSha256 = $afterHash
    }
}

if ($VerifyOnly) {
    foreach ($item in $rollbackPlan) {
        if ($item.BeforeSha256 -eq 'ABSENT') {
            "Rollback verified absent target: $($item.Target)"
        }
        else {
            "Rollback verified restored target: $($item.Target)"
        }
    }
    'Phase 12 rollback verification: PASS'
    return
}

foreach ($item in $rollbackPlan) {
    "Rollback plan: $($item.Target) -> $($item.BeforeSha256)"
}

$action = "restore $($rollbackPlan.Count) framework-owned target(s) from the fully validated manifest"
if (-not $PSCmdlet.ShouldProcess($manifestPath, $action)) {
    if ($WhatIfPreference) {
        'Phase 12 rollback preview: PASS'
    }
    else {
        'Phase 12 rollback cancelled.'
    }
    return
}

$transactionRoot = Join-Path ([System.IO.Path]::GetTempPath()) "phase-12-rollback-transaction-$([guid]::NewGuid().ToString('N'))"
$stagedState = @()
try {
    New-Item -ItemType Directory -Path $transactionRoot -ErrorAction Stop | Out-Null
    for ($index = 0; $index -lt $rollbackPlan.Count; $index++) {
        $item = $rollbackPlan[$index]
        $stagedPath = Join-Path $transactionRoot ("after-{0:D3}.bak" -f $index)
        Copy-Item -LiteralPath $item.Target -Destination $stagedPath -ErrorAction Stop
        if ((Get-FileHashOrAbsent -Path $stagedPath) -ne $item.AfterSha256) {
            throw "Rollback transaction staging hash mismatch: $($item.Target)"
        }
        $stagedState += [pscustomobject]@{
            Target = $item.Target
            Backup = $stagedPath
            AfterSha256 = $item.AfterSha256
        }
    }

    foreach ($item in $rollbackPlan) {
        if ($item.BeforeSha256 -eq 'ABSENT') {
            Remove-Item -LiteralPath $item.Target -Force -ErrorAction Stop
        }
        else {
            Copy-Item -LiteralPath $item.Backup -Destination $item.Target -Force -ErrorAction Stop
        }
        if ((Get-FileHashOrAbsent -Path $item.Target) -ne $item.BeforeSha256) {
            throw "Rollback target hash does not match BeforeSha256 after restore: $($item.Target)"
        }
        "Rollback restored target: $($item.Target)"
    }
}
catch {
    $failure = $_
    $compensationFailures = @()
    foreach ($staged in $stagedState) {
        try {
            Copy-Item -LiteralPath $staged.Backup -Destination $staged.Target -Force -ErrorAction Stop
            if ((Get-FileHashOrAbsent -Path $staged.Target) -ne $staged.AfterSha256) {
                throw "Compensation hash mismatch: $($staged.Target)"
            }
        }
        catch {
            $compensationFailures += $_.Exception.Message
        }
    }
    if ($compensationFailures.Count -gt 0) {
        throw "Phase 12 rollback failed and compensation was incomplete. Original failure: $($failure.Exception.Message). Compensation failures: $($compensationFailures -join ' | ')"
    }
    throw "Phase 12 rollback failed; all staged targets were restored to AfterSha256. $($failure.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $transactionRoot) {
        Remove-Item -LiteralPath $transactionRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($WhatIfPreference) {
    'Phase 12 rollback preview: PASS'
}
else {
    'Phase 12 rollback restore: PASS'
}
