[CmdletBinding()]
param(
    [string]$Root
)

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

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Set-TestFile {
    param([string]$Path, [string]$Content)

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Content -Encoding Ascii
}

function New-TestManifest {
    param(
        [string]$Path,
        [string]$Target,
        [string]$Backup,
        [string]$BeforeSha256
    )

    [ordered]@{
        phase = 'phase-12-test'
        entries = @(
            [ordered]@{
                Target = $Target
                Backup = $Backup
                BeforeSha256 = $BeforeSha256
            }
        )
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding Ascii
}

function Invoke-RollbackTest {
    param(
        [string]$ManifestPath,
        [switch]$WhatIf,
        [switch]$VerifyOnly,
        [string]$SimulatedProcessName
    )

    $previousUserProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $script:TestProfile
        # Tests control the process inventory without inspecting the real desktop.
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
        }
    }
    finally {
        $env:USERPROFILE = $previousUserProfile
    }
}

$rollbackScript = Join-Path $Root 'scripts\Invoke-Phase12RollbackDrill.ps1'
Assert-True -Condition (Test-Path -LiteralPath $rollbackScript -PathType Leaf) -Message "Rollback drill script not found: $rollbackScript"

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "phase-12-rollback-test-$([guid]::NewGuid().ToString('N'))"
try {
    New-Item -ItemType Directory -Path $temporaryRoot -ErrorAction Stop | Out-Null
    $TestProfile = Join-Path $temporaryRoot 'profile'
    New-Item -ItemType Directory -Path $TestProfile -ErrorAction Stop | Out-Null

    $validTarget = Join-Path $TestProfile '.config\opencode\sdd-personal\orchestrator.md'
    $validBackup = Join-Path $temporaryRoot 'valid-backup.md'
    $validManifest = Join-Path $temporaryRoot 'valid-manifest.json'
    Set-TestFile -Path $validTarget -Content 'candidate-value'
    Set-TestFile -Path $validBackup -Content 'baseline-value'
    $validBeforeHash = Get-TestHash -Path $validBackup
    New-TestManifest -Path $validManifest -Target $validTarget -Backup $validBackup -BeforeSha256 $validBeforeHash

    $validResult = Invoke-RollbackTest -ManifestPath $validManifest
    Assert-True -Condition ($validResult.ExitCode -eq 0) -Message "Valid manifest restore failed.`n$($validResult.Output)"
    Assert-True -Condition ($validResult.Output.Contains('Phase 12 rollback restore: PASS')) -Message 'Valid manifest restore did not report PASS.'
    Assert-True -Condition ((Get-TestHash -Path $validTarget) -eq $validBeforeHash) -Message 'Valid manifest restore did not restore the target hash.'

    $verifyResult = Invoke-RollbackTest -ManifestPath $validManifest -VerifyOnly
    Assert-True -Condition ($verifyResult.ExitCode -eq 0) -Message "Valid manifest verification failed.`n$($verifyResult.Output)"
    Assert-True -Condition ($verifyResult.Output.Contains('Phase 12 rollback verification: PASS')) -Message 'Valid manifest verification did not report PASS.'

    $noRuntimeTarget = Join-Path $TestProfile '.config\opencode\sdd-personal\no-runtime.md'
    $noRuntimeBackup = Join-Path $temporaryRoot 'no-runtime-backup.md'
    $noRuntimeManifest = Join-Path $temporaryRoot 'no-runtime-manifest.json'
    Set-TestFile -Path $noRuntimeTarget -Content 'candidate-value'
    Set-TestFile -Path $noRuntimeBackup -Content 'baseline-value'
    $noRuntimeBeforeHash = Get-TestHash -Path $noRuntimeBackup
    New-TestManifest -Path $noRuntimeManifest -Target $noRuntimeTarget -Backup $noRuntimeBackup -BeforeSha256 $noRuntimeBeforeHash

    # An empty simulated inventory proves the process guard permits a real restore.
    $noRuntimeResult = Invoke-RollbackTest -ManifestPath $noRuntimeManifest
    Assert-True -Condition ($noRuntimeResult.ExitCode -eq 0) -Message "Rollback failed without a runtime process.`n$($noRuntimeResult.Output)"
    Assert-True -Condition ($noRuntimeResult.Output.Contains('Phase 12 rollback restore: PASS')) -Message 'Rollback without a runtime process did not report PASS.'
    Assert-True -Condition ((Get-TestHash -Path $noRuntimeTarget) -eq $noRuntimeBeforeHash) -Message 'Rollback without a runtime process did not restore the target hash.'

    $malformedManifestTarget = Join-Path $TestProfile '.config\opencode\sdd-personal\malformed-manifest.md'
    $malformedManifest = Join-Path $temporaryRoot 'malformed-manifest.json'
    Set-TestFile -Path $malformedManifestTarget -Content 'candidate-value'
    Set-TestFile -Path $malformedManifest -Content '{ invalid json'
    $malformedCandidateHash = Get-TestHash -Path $malformedManifestTarget

    $malformedManifestResult = Invoke-RollbackTest -ManifestPath $malformedManifest
    Assert-True -Condition ($malformedManifestResult.ExitCode -ne 0) -Message 'Malformed manifest unexpectedly ran a rollback.'
    Assert-True -Condition (-not $malformedManifestResult.Output.Contains('Phase 12 rollback restore: PASS')) -Message 'Malformed manifest reported a rollback PASS.'
    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($malformedManifestResult.Output)) -Message 'Malformed manifest failure did not produce an error.'
    Assert-True -Condition ((Get-TestHash -Path $malformedManifestTarget) -eq $malformedCandidateHash) -Message 'Malformed manifest changed the candidate target.'

    $badHashTarget = Join-Path $TestProfile '.config\opencode\sdd-personal\bad-hash.md'
    $badHashBackup = Join-Path $temporaryRoot 'bad-hash-backup.md'
    $expectedBackup = Join-Path $temporaryRoot 'expected-backup.md'
    $badHashManifest = Join-Path $temporaryRoot 'bad-hash-manifest.json'
    Set-TestFile -Path $badHashTarget -Content 'candidate-value'
    Set-TestFile -Path $expectedBackup -Content 'baseline-value'
    Set-TestFile -Path $badHashBackup -Content 'tampered-backup-value'
    $candidateHash = Get-TestHash -Path $badHashTarget
    New-TestManifest -Path $badHashManifest -Target $badHashTarget -Backup $badHashBackup -BeforeSha256 (Get-TestHash -Path $expectedBackup)

    $badHashResult = Invoke-RollbackTest -ManifestPath $badHashManifest
    Assert-True -Condition ($badHashResult.ExitCode -ne 0) -Message 'Tampered backup unexpectedly restored a target.'
    Assert-True -Condition ($badHashResult.Output.Contains('Rollback backup hash does not match BeforeSha256')) -Message "Tampered backup did not report a hash mismatch.`n$($badHashResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $badHashTarget) -eq $candidateHash) -Message 'Tampered backup changed the target.'

    $invalidTarget = Join-Path $temporaryRoot 'outside-opencode.txt'
    $invalidBackup = Join-Path $temporaryRoot 'invalid-target-backup.txt'
    $invalidManifest = Join-Path $temporaryRoot 'invalid-target-manifest.json'
    Set-TestFile -Path $invalidTarget -Content 'candidate-value'
    Set-TestFile -Path $invalidBackup -Content 'baseline-value'
    $invalidTargetHash = Get-TestHash -Path $invalidTarget
    New-TestManifest -Path $invalidManifest -Target $invalidTarget -Backup $invalidBackup -BeforeSha256 (Get-TestHash -Path $invalidBackup)

    $invalidTargetResult = Invoke-RollbackTest -ManifestPath $invalidManifest
    Assert-True -Condition ($invalidTargetResult.ExitCode -ne 0) -Message 'Target outside the OpenCode root unexpectedly restored.'
    Assert-True -Condition ($invalidTargetResult.Output.Contains('Rollback target is outside the OpenCode configuration root')) -Message "Invalid target did not report the expected boundary failure.`n$($invalidTargetResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $invalidTarget) -eq $invalidTargetHash) -Message 'Invalid target was modified.'

    $whatIfTarget = Join-Path $TestProfile '.config\opencode\sdd-personal\what-if.md'
    $whatIfBackup = Join-Path $temporaryRoot 'what-if-backup.md'
    $whatIfManifest = Join-Path $temporaryRoot 'what-if-manifest.json'
    Set-TestFile -Path $whatIfTarget -Content 'candidate-value'
    Set-TestFile -Path $whatIfBackup -Content 'baseline-value'
    $whatIfCandidateHash = Get-TestHash -Path $whatIfTarget
    New-TestManifest -Path $whatIfManifest -Target $whatIfTarget -Backup $whatIfBackup -BeforeSha256 (Get-TestHash -Path $whatIfBackup)

    $whatIfResult = Invoke-RollbackTest -ManifestPath $whatIfManifest -WhatIf
    Assert-True -Condition ($whatIfResult.ExitCode -eq 0) -Message "Rollback WhatIf failed.`n$($whatIfResult.Output)"
    Assert-True -Condition ($whatIfResult.Output.Contains('Phase 12 rollback preview: PASS')) -Message 'Rollback WhatIf did not report preview PASS.'
    Assert-True -Condition ((Get-TestHash -Path $whatIfTarget) -eq $whatIfCandidateHash) -Message 'Rollback WhatIf changed the target.'

    foreach ($processCase in @(
        [pscustomobject]@{ Name = 'OpenChamber'; Label = 'OpenChamber' },
        [pscustomobject]@{ Name = 'CPA-GUI'; Label = 'CPA GUI' },
        [pscustomobject]@{ Name = 'opencode'; Label = 'opencode' }
    )) {
        $processTarget = Join-Path $TestProfile ".config\opencode\sdd-personal\blocked-$($processCase.Name).md"
        $processBackup = Join-Path $temporaryRoot "blocked-$($processCase.Name)-backup.md"
        $processManifest = Join-Path $temporaryRoot "blocked-$($processCase.Name)-manifest.json"
        Set-TestFile -Path $processTarget -Content 'candidate-value'
        Set-TestFile -Path $processBackup -Content 'baseline-value'
        $processTargetHash = Get-TestHash -Path $processTarget
        New-TestManifest -Path $processManifest -Target $processTarget -Backup $processBackup -BeforeSha256 (Get-TestHash -Path $processBackup)

        $processResult = Invoke-RollbackTest -ManifestPath $processManifest -SimulatedProcessName $processCase.Name
        Assert-True -Condition ($processResult.ExitCode -ne 0) -Message "Rollback unexpectedly ran while $($processCase.Label) was active."
        Assert-True -Condition ($processResult.Output.Contains('Close OpenChamber and CPA GUI before a rollback drill.')) -Message "Rollback did not reject active $($processCase.Label).`n$($processResult.Output)"
        Assert-True -Condition ($processResult.Output.Contains("$($processCase.Name) (PID 4242)")) -Message "Rollback did not identify active $($processCase.Label).`n$($processResult.Output)"
        Assert-True -Condition ((Get-TestHash -Path $processTarget) -eq $processTargetHash) -Message "Rollback changed a target while $($processCase.Label) was active."
    }

    'Phase 12 rollback drill: PASS'
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
