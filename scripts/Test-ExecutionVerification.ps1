[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Read-Record {
    param([string]$Path)

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Invalid execution fixture '$Path'. $($_.Exception.Message)"
    }
}

function Test-SuccessfulValidation {
    param([object]$Validation)

    if ($null -eq $Validation) { return $false }
    if ([string]::IsNullOrWhiteSpace([string]$Validation.command)) { return $false }
    if ([string]::IsNullOrWhiteSpace([string]$Validation.output)) { return $false }
    if ($null -eq $Validation.exitCode) { return $false }
    if ($Validation.exitCode -isnot [int] -and $Validation.exitCode -isnot [long]) { return $false }
    return ($Validation.exitCode -eq 0)
}

function Test-AttemptedValidation {
    param([object]$Validation)

    if ($null -eq $Validation) { return $false }
    return -not [string]::IsNullOrWhiteSpace([string]$Validation.command)
}

function Get-ExecutionVerdict {
    param([object]$Record)

    foreach ($field in @('observableOutcome', 'allowedFiles', 'interfacesAndInvariants', 'acceptanceCriteria', 'focusedValidation', 'forbiddenScopeChanges', 'expectedFinalReport')) {
        if ($null -eq $Record.brief.$field -or @($Record.brief.$field).Count -eq 0 -or [string]::IsNullOrWhiteSpace(($Record.brief.$field -join ''))) {
            return 'INVALID-BRIEF'
        }
    }

    if ($Record.worker.role -ne 'fixer' -or $Record.worker.model -ne 'minimax-coding-plan/MiniMax-M3') {
        return 'INVALID-WORKER-ROUTE'
    }

    if ([string]::IsNullOrWhiteSpace([string]$Record.taskId)) {
        return 'MISSING-TASK-ID'
    }
    if ([string]$Record.taskId -notmatch '^[A-Za-z][A-Za-z0-9._:-]{2,127}$') {
        return 'INVALID-TASK-ID'
    }

    $allValidations = @()
    foreach ($attempt in @($Record.attempts)) {
        foreach ($validation in @($attempt.validations)) {
            $allValidations += $validation
        }
    }

    $focusedCommands = @($Record.brief.focusedValidation | ForEach-Object { [string]$_ })
    $successfulCount = @($allValidations | Where-Object {
        (Test-SuccessfulValidation -Validation $_) -and $focusedCommands -contains [string]$_.command
    }).Count

    if ($Record.completion -eq 'PASS' -and $successfulCount -lt 1) {
        return 'FALSE-PASS-BLOCKED'
    }

    $brokenOrFailedCount = @($allValidations | Where-Object {
        -not (Test-SuccessfulValidation -Validation $_)
    }).Count

    if ($brokenOrFailedCount -ge 2) {
        if ($Record.escalation.role -eq 'oracle' -and $Record.escalation.reason -eq 'assumption-review' -and $Record.completion -eq 'ESCALATE') {
            return 'ESCALATE'
        }
        return 'MISSING-ESCALATION'
    }

    if ($brokenOrFailedCount -gt 0) {
        if ($Record.completion -eq 'PASS') {
            return 'FALSE-PASS-BLOCKED'
        }
        return 'BLOCKED'
    }

    if ($Record.kind -eq 'bug' -and ($null -eq $Record.regression -or $null -eq $Record.regression.before -or $null -eq $Record.regression.after -or $Record.regression.before.exitCode -eq 0 -or $Record.regression.after.exitCode -ne 0)) {
        return 'MISSING-REGRESSION-EVIDENCE'
    }

    if ($Record.completion -eq 'PASS') {
        return 'PASS'
    }
    return 'INCOMPLETE'
}

function Assert-Equal {
    param([string]$Actual, [string]$Expected, [string]$Message)

    if ($Actual -cne $Expected) {
        throw "$Message Expected '$Expected'; received '$Actual'."
    }
}

function Assert-Verdict {
    param([object]$Record, [string]$Expected, [string]$RelativePath)

    $actual = Get-ExecutionVerdict -Record $Record
    if ($actual -cne $Expected) {
        throw "Unexpected verdict for $RelativePath. Expected '$Expected'; received '$actual'."
    }
}

function Assert-GateRejects {
    param([string]$RelativePath, [string]$ExpectedVerdict)

    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 7 fixture not found: $RelativePath"
    }
    $record = Read-Record -Path $path
    Assert-Verdict -Record $record -Expected $ExpectedVerdict -RelativePath $RelativePath
}

$positiveFixtures = @{
    'fixtures\phase-7\feature\record.json' = 'PASS'
    'fixtures\phase-7\bug\record.json' = 'PASS'
    'fixtures\phase-7\failed-command-false-pass.json' = 'FALSE-PASS-BLOCKED'
    'fixtures\phase-7\two-failed-repairs.json' = 'ESCALATE'
    'fixtures\phase-7\missing-task-id.json' = 'MISSING-TASK-ID'
    'fixtures\phase-7\invalid-task-id.json' = 'INVALID-TASK-ID'
    'fixtures\phase-7\empty-command.json' = 'FALSE-PASS-BLOCKED'
    'fixtures\phase-7\empty-output.json' = 'FALSE-PASS-BLOCKED'
    'fixtures\phase-7\no-attempts.json' = 'FALSE-PASS-BLOCKED'
    'fixtures\phase-7\missing-regression-evidence.json' = 'MISSING-REGRESSION-EVIDENCE'
}

foreach ($relativePath in $positiveFixtures.Keys) {
    Assert-GateRejects -RelativePath $relativePath -ExpectedVerdict $positiveFixtures[$relativePath]
}

$presetPath = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$preset = Get-Content -LiteralPath $presetPath -Raw | ConvertFrom-Json -ErrorAction Stop
Assert-Equal -Actual $preset.presets.'sdd-personal'.fixer.model[0].id -Expected 'minimax-coding-plan/MiniMax-M3' -Message 'Fixer must use M3 as its primary worker model.'
foreach ($skill in @('systematic-debugging', 'verification-before-completion')) {
    if ($preset.presets.'sdd-personal'.fixer.skills -notcontains $skill) {
        throw "Fixer must load the '$skill' skill."
    }
}

$promptRoot = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal'
$requiredPromptRules = @{
    'orchestrator.md' = @('Task Brief', 'two failed repair attempts', 'M3 Fixer')
    'fixer.md' = @('Task Brief Contract', 'second failed validation', 'every required validation exited 0')
    'oracle.md' = @('two failed repair attempts', 'assumption', 'not a default completion gate')
}
foreach ($promptFile in $requiredPromptRules.Keys) {
    $path = Join-Path $promptRoot $promptFile
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 7 prompt source not found: $path"
    }
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($rule in $requiredPromptRules[$promptFile]) {
        if (-not $content.Contains($rule)) {
            throw "$promptFile is missing its required Phase 7 rule: $rule"
        }
    }
}

foreach ($skill in @('systematic-debugging', 'verification-before-completion')) {
    $path = Join-Path $Root "skills\$skill\SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 7 skill not found: $path"
    }
}

foreach ($script in @('Apply-ExecutionVerification.ps1', 'Test-ExecutionVerificationApply.ps1', 'Test-ExecutionVerificationRuntime.ps1')) {
    $path = Join-Path $Root "scripts\$script"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 7 lifecycle script not found: $path"
    }
}

$applySource = Get-Content -LiteralPath (Join-Path $Root 'scripts\Apply-ExecutionVerification.ps1') -Raw
foreach ($rule in @("Merge = 'fixer.skills'", 'Merge = $item.Merge', "if (`$entry.Merge -eq 'fixer.skills')", 'Add-Member -NotePropertyName skills', 'Get-FileHashOrAbsent', 'Restore-Target', 'Write-JsonUtf8NoBom', 'UTF8Encoding]::new($false)', 'manifest.json', 'changed targets were restored')) {
    if (-not $applySource.Contains($rule)) {
        throw "Phase 7 apply script is missing required fail-closed lifecycle rule: $rule"
    }
}

'Phase 7 execution and verification: PASS'
