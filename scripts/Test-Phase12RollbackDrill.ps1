[CmdletBinding()]
param(
    [string]$Root
)

Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) {
        throw $Message
    }
}

function Get-TestHash {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 'ABSENT'
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Set-TestFile {
    param([string]$Path, [string]$Content)

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::ASCII)
}

function New-TestEntry {
    param(
        [string]$Target,
        [string]$Backup,
        [string]$BeforeSha256,
        [string]$AfterSha256
    )

    return [ordered]@{
        Target = $Target
        Backup = $Backup
        BeforeSha256 = $BeforeSha256
        AfterSha256 = $AfterSha256
    }
}

function New-TestManifest {
    param(
        [string]$Path,
        [object[]]$Entries
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    [ordered]@{
        phase = 'phase-12-test'
        entries = $Entries
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding Ascii
}

function New-RestoreCase {
    param(
        [string]$CaseName,
        [string]$RelativeTarget,
        [string]$BeforeContent = 'baseline-value',
        [string]$AfterContent = 'candidate-value'
    )

    $caseRoot = Join-Path $script:TemporaryRoot $CaseName
    New-Item -ItemType Directory -Path $caseRoot -Force -ErrorAction Stop | Out-Null
    $target = Join-Path $script:OpenCodeRoot $RelativeTarget
    $backup = Join-Path $caseRoot 'backup.bin'
    $manifest = Join-Path $caseRoot 'manifest.json'
    Set-TestFile -Path $target -Content $AfterContent
    Set-TestFile -Path $backup -Content $BeforeContent
    $entry = New-TestEntry `
        -Target $target `
        -Backup $backup `
        -BeforeSha256 (Get-TestHash -Path $backup) `
        -AfterSha256 (Get-TestHash -Path $target)
    New-TestManifest -Path $manifest -Entries @($entry)

    return [pscustomobject]@{
        Root = $caseRoot
        Target = $target
        Backup = $backup
        Manifest = $manifest
        BeforeSha256 = $entry.BeforeSha256
        AfterSha256 = $entry.AfterSha256
    }
}

function Invoke-RollbackTest {
    param(
        [string]$ManifestPath,
        [switch]$WhatIf,
        [switch]$VerifyOnly,
        [string]$SimulatedProcessName,
        [string]$FailCopySource,
        [string]$FailCopyDestination
    )

    $previousUserProfile = $env:USERPROFILE
    $copyFailureState = @{ Triggered = $false }
    try {
        $env:USERPROFILE = $script:TestProfile
        Set-StrictMode -Off

        function Get-Process {
            [CmdletBinding()]
            param()

            if (-not [string]::IsNullOrWhiteSpace($SimulatedProcessName)) {
                return [pscustomobject]@{
                    ProcessName = $SimulatedProcessName
                    Id = 4242
                }
            }
            return @()
        }

        function Copy-Item {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [string]$LiteralPath,
                [Parameter(Mandatory)]
                [string]$Destination,
                [switch]$Force
            )

            $shouldFail = -not $copyFailureState.Triggered -and
                -not [string]::IsNullOrWhiteSpace($FailCopySource) -and
                -not [string]::IsNullOrWhiteSpace($FailCopyDestination) -and
                ([System.IO.Path]::GetFullPath($LiteralPath) -eq [System.IO.Path]::GetFullPath($FailCopySource)) -and
                ([System.IO.Path]::GetFullPath($Destination) -eq [System.IO.Path]::GetFullPath($FailCopyDestination))
            if ($shouldFail) {
                $copyFailureState.Triggered = $true
                throw "Injected restore failure: $Destination"
            }

            Microsoft.PowerShell.Management\Copy-Item @PSBoundParameters
        }

        try {
            if ($WhatIf) {
                $output = & $script:RollbackScript -ManifestPath $ManifestPath -WhatIf 2>&1 | Out-String
            }
            elseif ($VerifyOnly) {
                $output = & $script:RollbackScript -ManifestPath $ManifestPath -VerifyOnly 2>&1 | Out-String
            }
            else {
                $output = & $script:RollbackScript -ManifestPath $ManifestPath -Confirm:$false 2>&1 | Out-String
            }
            $exitCode = 0
        }
        catch {
            $output = ($_ | Out-String)
            $exitCode = 1
        }

        return [pscustomobject]@{
            ExitCode = $exitCode
            Output = $output
            CopyFailureTriggered = $copyFailureState.Triggered
        }
    }
    finally {
        $env:USERPROFILE = $previousUserProfile
    }
}

$RollbackScript = Join-Path $Root 'scripts\Invoke-Phase12RollbackDrill.ps1'
Assert-True -Condition (Test-Path -LiteralPath $RollbackScript -PathType Leaf) -Message "Rollback drill script not found: $RollbackScript"

$TemporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "phase-12-rollback-test-$([guid]::NewGuid().ToString('N'))"
try {
    New-Item -ItemType Directory -Path $TemporaryRoot -ErrorAction Stop | Out-Null
    $TestProfile = Join-Path $TemporaryRoot 'profile'
    $OpenCodeRoot = Join-Path $TestProfile '.config\opencode'
    New-Item -ItemType Directory -Path $OpenCodeRoot -Force -ErrorAction Stop | Out-Null

    $validCase = New-RestoreCase -CaseName 'valid' -RelativeTarget 'opencode.jsonc'
    $validResult = Invoke-RollbackTest -ManifestPath $validCase.Manifest
    Assert-True -Condition ($validResult.ExitCode -eq 0) -Message "Valid manifest restore failed.`n$($validResult.Output)"
    Assert-True -Condition ($validResult.Output.Contains('Phase 12 rollback restore: PASS')) -Message 'Valid manifest restore did not report PASS.'
    Assert-True -Condition ((Get-TestHash -Path $validCase.Target) -eq $validCase.BeforeSha256) -Message 'Valid manifest restore did not restore the target hash.'

    $verifyResult = Invoke-RollbackTest -ManifestPath $validCase.Manifest -VerifyOnly
    Assert-True -Condition ($verifyResult.ExitCode -eq 0) -Message "Valid manifest verification failed.`n$($verifyResult.Output)"
    Assert-True -Condition ($verifyResult.Output.Contains('Phase 12 rollback verification: PASS')) -Message 'Valid manifest verification did not report PASS.'

    $absentRoot = Join-Path $TemporaryRoot 'absent-valid'
    New-Item -ItemType Directory -Path $absentRoot -Force -ErrorAction Stop | Out-Null
    $absentTarget = Join-Path $OpenCodeRoot 'oh-my-opencode-slim.json'
    $absentManifest = Join-Path $absentRoot 'manifest.json'
    Set-TestFile -Path $absentTarget -Content 'candidate-created-by-apply'
    $absentAfterHash = Get-TestHash -Path $absentTarget
    New-TestManifest -Path $absentManifest -Entries @(
        (New-TestEntry -Target $absentTarget -Backup 'ABSENT' -BeforeSha256 'ABSENT' -AfterSha256 $absentAfterHash)
    )
    $absentResult = Invoke-RollbackTest -ManifestPath $absentManifest
    Assert-True -Condition ($absentResult.ExitCode -eq 0) -Message "ABSENT restore failed.`n$($absentResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $absentTarget) -eq 'ABSENT') -Message 'ABSENT restore did not remove the created target.'
    $absentVerifyResult = Invoke-RollbackTest -ManifestPath $absentManifest -VerifyOnly
    Assert-True -Condition ($absentVerifyResult.ExitCode -eq 0) -Message "ABSENT verification failed.`n$($absentVerifyResult.Output)"

    $staleCase = New-RestoreCase -CaseName 'stale-current' -RelativeTarget 'oh-my-opencode-slim\sdd-personal\orchestrator.md'
    Set-TestFile -Path $staleCase.Target -Content 'user-changed-after-apply'
    $staleHash = Get-TestHash -Path $staleCase.Target
    $staleResult = Invoke-RollbackTest -ManifestPath $staleCase.Manifest
    Assert-True -Condition ($staleResult.ExitCode -ne 0) -Message 'A stale current target unexpectedly restored.'
    Assert-True -Condition ($staleResult.Output.Contains('target hash does not match AfterSha256')) -Message "A stale current target did not report the AfterSha256 mismatch.`n$($staleResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $staleCase.Target) -eq $staleHash) -Message 'A stale current target was modified.'

    $staleAbsentRoot = Join-Path $TemporaryRoot 'stale-absent'
    New-Item -ItemType Directory -Path $staleAbsentRoot -Force -ErrorAction Stop | Out-Null
    $staleAbsentTarget = Join-Path $OpenCodeRoot 'oh-my-opencode-slim\sdd-personal\explorer.md'
    $staleAbsentManifest = Join-Path $staleAbsentRoot 'manifest.json'
    Set-TestFile -Path $staleAbsentTarget -Content 'candidate-created-by-apply'
    New-TestManifest -Path $staleAbsentManifest -Entries @(
        (New-TestEntry -Target $staleAbsentTarget -Backup 'ABSENT' -BeforeSha256 'ABSENT' -AfterSha256 (Get-TestHash -Path $staleAbsentTarget))
    )
    Set-TestFile -Path $staleAbsentTarget -Content 'user-replaced-created-target'
    $staleAbsentHash = Get-TestHash -Path $staleAbsentTarget
    $staleAbsentResult = Invoke-RollbackTest -ManifestPath $staleAbsentManifest
    Assert-True -Condition ($staleAbsentResult.ExitCode -ne 0) -Message 'A stale ABSENT target was unexpectedly removed.'
    Assert-True -Condition ($staleAbsentResult.Output.Contains('target hash does not match AfterSha256')) -Message "A stale ABSENT target did not report the AfterSha256 mismatch.`n$($staleAbsentResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $staleAbsentTarget) -eq $staleAbsentHash) -Message 'A stale ABSENT target was removed or modified.'

    $forbiddenRoot = Join-Path $TemporaryRoot 'forbidden-target'
    New-Item -ItemType Directory -Path $forbiddenRoot -Force -ErrorAction Stop | Out-Null
    $forbiddenTarget = Join-Path $OpenCodeRoot 'opencode.json'
    $forbiddenBackup = Join-Path $forbiddenRoot 'backup.json'
    $forbiddenManifest = Join-Path $forbiddenRoot 'manifest.json'
    Set-TestFile -Path $forbiddenTarget -Content 'candidate-value'
    Set-TestFile -Path $forbiddenBackup -Content 'baseline-value'
    $forbiddenHash = Get-TestHash -Path $forbiddenTarget
    New-TestManifest -Path $forbiddenManifest -Entries @(
        (New-TestEntry -Target $forbiddenTarget -Backup $forbiddenBackup -BeforeSha256 (Get-TestHash -Path $forbiddenBackup) -AfterSha256 $forbiddenHash)
    )
    $forbiddenResult = Invoke-RollbackTest -ManifestPath $forbiddenManifest
    Assert-True -Condition ($forbiddenResult.ExitCode -ne 0) -Message 'The forbidden opencode.json target unexpectedly restored.'
    Assert-True -Condition ($forbiddenResult.Output.Contains('not a named framework-owned target')) -Message "The forbidden target did not report the allowlist failure.`n$($forbiddenResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $forbiddenTarget) -eq $forbiddenHash) -Message 'The forbidden target was modified.'

    $tamperedCase = New-RestoreCase -CaseName 'tampered-backup' -RelativeTarget 'skills\ui-quality\SKILL.md'
    Set-TestFile -Path $tamperedCase.Backup -Content 'tampered-backup-value'
    $tamperedResult = Invoke-RollbackTest -ManifestPath $tamperedCase.Manifest
    Assert-True -Condition ($tamperedResult.ExitCode -ne 0) -Message 'A tampered backup unexpectedly restored.'
    Assert-True -Condition ($tamperedResult.Output.Contains('Rollback backup hash does not match BeforeSha256')) -Message "A tampered backup did not report the hash mismatch.`n$($tamperedResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $tamperedCase.Target) -eq $tamperedCase.AfterSha256) -Message 'A tampered backup modified the target.'

    $outsideBackupRoot = Join-Path $TemporaryRoot 'outside-backup'
    $outsideManifestRoot = Join-Path $outsideBackupRoot 'manifest'
    New-Item -ItemType Directory -Path $outsideManifestRoot -Force -ErrorAction Stop | Out-Null
    $outsideBackupTarget = Join-Path $OpenCodeRoot 'skills\package-and-release\SKILL.md'
    $outsideBackup = Join-Path $outsideBackupRoot 'backup.bin'
    $outsideManifest = Join-Path $outsideManifestRoot 'manifest.json'
    Set-TestFile -Path $outsideBackupTarget -Content 'candidate-value'
    Set-TestFile -Path $outsideBackup -Content 'baseline-value'
    $outsideBackupAfterHash = Get-TestHash -Path $outsideBackupTarget
    New-TestManifest -Path $outsideManifest -Entries @(
        (New-TestEntry -Target $outsideBackupTarget -Backup $outsideBackup -BeforeSha256 (Get-TestHash -Path $outsideBackup) -AfterSha256 $outsideBackupAfterHash)
    )
    $outsideBackupResult = Invoke-RollbackTest -ManifestPath $outsideManifest
    Assert-True -Condition ($outsideBackupResult.ExitCode -ne 0) -Message 'A backup outside the manifest directory unexpectedly restored.'
    Assert-True -Condition ($outsideBackupResult.Output.Contains('outside its approved root')) -Message "An outside backup did not report the containment failure.`n$($outsideBackupResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $outsideBackupTarget) -eq $outsideBackupAfterHash) -Message 'An outside backup modified the target.'

    $preflightFirst = New-RestoreCase -CaseName 'preflight-first' -RelativeTarget 'oh-my-opencode-slim\sdd-personal\librarian.md'
    $preflightSecond = New-RestoreCase -CaseName 'preflight-second' -RelativeTarget 'oh-my-opencode-slim\sdd-personal\fixer.md'
    Set-TestFile -Path $preflightSecond.Target -Content 'late-invalid-current-state'
    $preflightManifest = Join-Path $TemporaryRoot 'preflight-manifest.json'
    New-TestManifest -Path $preflightManifest -Entries @(
        (New-TestEntry -Target $preflightFirst.Target -Backup $preflightFirst.Backup -BeforeSha256 $preflightFirst.BeforeSha256 -AfterSha256 $preflightFirst.AfterSha256),
        (New-TestEntry -Target $preflightSecond.Target -Backup $preflightSecond.Backup -BeforeSha256 $preflightSecond.BeforeSha256 -AfterSha256 $preflightSecond.AfterSha256)
    )
    $preflightFirstHash = Get-TestHash -Path $preflightFirst.Target
    $preflightSecondHash = Get-TestHash -Path $preflightSecond.Target
    $preflightResult = Invoke-RollbackTest -ManifestPath $preflightManifest
    Assert-True -Condition ($preflightResult.ExitCode -ne 0) -Message 'A manifest with a late invalid entry unexpectedly restored.'
    Assert-True -Condition ((Get-TestHash -Path $preflightFirst.Target) -eq $preflightFirstHash) -Message 'Full-manifest preflight modified the first valid target.'
    Assert-True -Condition ((Get-TestHash -Path $preflightSecond.Target) -eq $preflightSecondHash) -Message 'Full-manifest preflight modified the late invalid target.'

    $duplicateCase = New-RestoreCase -CaseName 'duplicate' -RelativeTarget 'oh-my-opencode-slim\sdd-personal\oracle.md'
    $duplicateManifest = Join-Path $duplicateCase.Root 'duplicate-manifest.json'
    $duplicateEntry = New-TestEntry -Target $duplicateCase.Target -Backup $duplicateCase.Backup -BeforeSha256 $duplicateCase.BeforeSha256 -AfterSha256 $duplicateCase.AfterSha256
    New-TestManifest -Path $duplicateManifest -Entries @($duplicateEntry, $duplicateEntry)
    $duplicateResult = Invoke-RollbackTest -ManifestPath $duplicateManifest
    Assert-True -Condition ($duplicateResult.ExitCode -ne 0) -Message 'A duplicate rollback target unexpectedly restored.'
    Assert-True -Condition ($duplicateResult.Output.Contains('duplicate target')) -Message "A duplicate target did not report the expected failure.`n$($duplicateResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $duplicateCase.Target) -eq $duplicateCase.AfterSha256) -Message 'A duplicate target manifest modified the target.'

    $whatIfCase = New-RestoreCase -CaseName 'what-if' -RelativeTarget 'oh-my-opencode-slim\sdd-personal\designer.md'
    $whatIfResult = Invoke-RollbackTest -ManifestPath $whatIfCase.Manifest -WhatIf
    Assert-True -Condition ($whatIfResult.ExitCode -eq 0) -Message "Rollback WhatIf failed.`n$($whatIfResult.Output)"
    Assert-True -Condition ($whatIfResult.Output.Contains('Phase 12 rollback preview: PASS')) -Message 'Rollback WhatIf did not report preview PASS.'
    Assert-True -Condition ((Get-TestHash -Path $whatIfCase.Target) -eq $whatIfCase.AfterSha256) -Message 'Rollback WhatIf changed the target.'

    $transactionFirst = New-RestoreCase -CaseName 'transaction-first' -RelativeTarget 'oh-my-opencode-slim\sdd-personal\observer.md'
    $transactionSecond = New-RestoreCase -CaseName 'transaction-second' -RelativeTarget 'skills\source-first-research\SKILL.md'
    $transactionManifest = Join-Path $TemporaryRoot 'transaction-manifest.json'
    New-TestManifest -Path $transactionManifest -Entries @(
        (New-TestEntry -Target $transactionFirst.Target -Backup $transactionFirst.Backup -BeforeSha256 $transactionFirst.BeforeSha256 -AfterSha256 $transactionFirst.AfterSha256),
        (New-TestEntry -Target $transactionSecond.Target -Backup $transactionSecond.Backup -BeforeSha256 $transactionSecond.BeforeSha256 -AfterSha256 $transactionSecond.AfterSha256)
    )
    $transactionResult = Invoke-RollbackTest `
        -ManifestPath $transactionManifest `
        -FailCopySource $transactionSecond.Backup `
        -FailCopyDestination $transactionSecond.Target
    Assert-True -Condition ($transactionResult.ExitCode -ne 0) -Message 'The injected second restore failure unexpectedly passed.'
    Assert-True -Condition $transactionResult.CopyFailureTriggered -Message 'The second restore failure injection did not run.'
    Assert-True -Condition ($transactionResult.Output.Contains('all staged targets were restored to AfterSha256')) -Message "Rollback did not report successful compensation.`n$($transactionResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $transactionFirst.Target) -eq $transactionFirst.AfterSha256) -Message 'Compensation did not restore the first target to AfterSha256.'
    Assert-True -Condition ((Get-TestHash -Path $transactionSecond.Target) -eq $transactionSecond.AfterSha256) -Message 'Compensation did not preserve the second target at AfterSha256.'

    $malformedTarget = Join-Path $OpenCodeRoot 'skills\systematic-debugging\SKILL.md'
    $malformedManifest = Join-Path $TemporaryRoot 'malformed-manifest.json'
    Set-TestFile -Path $malformedTarget -Content 'candidate-value'
    Set-TestFile -Path $malformedManifest -Content '{ invalid json'
    $malformedHash = Get-TestHash -Path $malformedTarget
    $malformedResult = Invoke-RollbackTest -ManifestPath $malformedManifest
    Assert-True -Condition ($malformedResult.ExitCode -ne 0) -Message 'Malformed manifest unexpectedly ran a rollback.'
    Assert-True -Condition ((Get-TestHash -Path $malformedTarget) -eq $malformedHash) -Message 'Malformed manifest changed a target.'

    foreach ($processName in @('OpenChamber', 'CPA-GUI', 'opencode')) {
        $processCase = New-RestoreCase -CaseName "blocked-$processName" -RelativeTarget 'skills\verification-before-completion\SKILL.md'
        $processResult = Invoke-RollbackTest -ManifestPath $processCase.Manifest -SimulatedProcessName $processName
        Assert-True -Condition ($processResult.ExitCode -ne 0) -Message "Rollback unexpectedly ran while $processName was active."
        Assert-True -Condition ($processResult.Output.Contains('Close OpenChamber and CPA GUI before a rollback drill.')) -Message "Rollback did not reject active $processName.`n$($processResult.Output)"
        Assert-True -Condition ((Get-TestHash -Path $processCase.Target) -eq $processCase.AfterSha256) -Message "Rollback changed a target while $processName was active."
    }

    'Phase 12 rollback drill: PASS'
}
finally {
    if (Test-Path -LiteralPath $TemporaryRoot) {
        Remove-Item -LiteralPath $TemporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
