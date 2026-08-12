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

function Get-AdvisoryVerdict {
    param([object]$Scenario)

    switch ($Scenario.situation) {
        'short-question' { return 'neither' }
        'clear-bounded-request' {
            foreach ($requirement in @('objective-clear', 'scope-clear', 'completion-evidence')) {
                if ($Scenario.requires -notcontains $requirement) { return 'missing-fast-path-precondition' }
            }
            return 'fast-path-no-interview'
        }
        'complex-unresolved-request' {
            foreach ($requirement in @('coherent-topic-rounds', 'decision-ready-stop', 'no-fixed-cap')) {
                if ($Scenario.requires -notcontains $requirement) { return 'invalid-adaptive-interview' }
            }
            return 'adaptive-interview-no-goal'
        }
        'long-structured-input' { return 'focus' }
        'ui-direction-unresolved' { return 'focus-no-goal' }
        'approved-multi-step-implementation' {
            foreach ($requirement in @('self-contained-objective', 'completion-evidence', 'decisions-resolved', 'safe-continuation', 'budget', 'blocked-conditions', 'non-overlapping-writer', 'isolated-worktree')) {
                if ($Scenario.requires -notcontains $requirement) {
                    return 'missing-goal-precondition'
                }
            }
            return 'worktree-goal'
        }
        'isolation-needed-unresolved-scope' { return 'worktree-only' }
        'readonly-deterministic-work' {
            foreach ($requirement in @('self-contained-objective', 'completion-evidence', 'decisions-resolved', 'safe-continuation', 'budget', 'blocked-conditions', 'non-overlapping-writer', 'read-only')) {
                if ($Scenario.requires -notcontains $requirement) { return 'missing-goal-precondition' }
            }
            return 'goal-only'
        }
        'approved-writing-no-worktree' {
            foreach ($requirement in @('self-contained-objective', 'completion-evidence', 'decisions-resolved', 'safe-continuation', 'budget', 'blocked-conditions', 'non-overlapping-writer')) {
                if ($Scenario.requires -notcontains $requirement) { return 'missing-goal-precondition' }
            }
            if ($Scenario.requires -contains 'isolated-worktree') { return 'unexpected-worktree-state' }
            return 'worktree-required-before-goal'
        }
        'approved-writing-in-worktree' {
            foreach ($requirement in @('self-contained-objective', 'completion-evidence', 'decisions-resolved', 'safe-continuation', 'budget', 'blocked-conditions', 'non-overlapping-writer', 'isolated-worktree')) {
                if ($Scenario.requires -notcontains $requirement) { return 'missing-goal-precondition' }
            }
            return 'goal-in-existing-worktree'
        }
        'goal-new-material-decision' {
            foreach ($requirement in @('goal-active', 'material-decision', 'pause', 'user-choice')) {
                if ($Scenario.requires -notcontains $requirement) { return 'unsafe-goal-continuation' }
            }
            return 'pause-for-decision'
        }
        'goal-budget-reached' {
            foreach ($requirement in @('progress-summary', 'remaining-work', 'user-choice', 'no-auto-budget', 'no-auto-resume')) {
                if ($Scenario.requires -notcontains $requirement) { return 'unsafe-budget-continuation' }
            }
            return 'no-auto-resume'
        }
        'release-preparation' {
            foreach ($requirement in @('package-evidence', 'release-summary', 'rollback-plan', 'ready-for-release', 'no-external-action', 'no-archive')) {
                if ($Scenario.requires -notcontains $requirement) { return 'unsafe-release-goal' }
            }
            return 'goal-to-ready-for-release'
        }
        'independent-alternatives' {
            foreach ($requirement in @('comparison-value', 'isolated-writers', 'user-decision')) {
                if ($Scenario.requires -notcontains $requirement) {
                    return 'missing-multirun-precondition'
                }
            }
            return 'multirun-isolated'
        }
        'release-action' { return 'stop-for-approval' }
        default { return 'unknown-situation' }
    }
}

# Verdict expectations and fixed scenario coverage are owned by code.
$requiredPhase8Scenarios = [ordered]@{
    'small-question'                = @{ situation = 'short-question';                          expected = 'neither' }
    'clear-bounded-fast-path'       = @{ situation = 'clear-bounded-request';                   expected = 'fast-path-no-interview' }
    'complex-adaptive-interview'    = @{ situation = 'complex-unresolved-request';              expected = 'adaptive-interview-no-goal' }
    'long-requirements'             = @{ situation = 'long-structured-input';                   expected = 'focus' }
    'unresolved-ui-direction'       = @{ situation = 'ui-direction-unresolved';                 expected = 'focus-no-goal' }
    'approved-feature'              = @{ situation = 'approved-multi-step-implementation';      expected = 'worktree-goal' }
    'incomplete-goal-request'       = @{ situation = 'approved-multi-step-implementation';      expected = 'missing-goal-precondition' }
    'isolation-without-finish-line' = @{ situation = 'isolation-needed-unresolved-scope';       expected = 'worktree-only' }
    'readonly-verification-goal'    = @{ situation = 'readonly-deterministic-work';              expected = 'goal-only' }
    'writing-without-worktree'      = @{ situation = 'approved-writing-no-worktree';             expected = 'worktree-required-before-goal' }
    'writing-in-existing-worktree'  = @{ situation = 'approved-writing-in-worktree';             expected = 'goal-in-existing-worktree' }
    'goal-material-decision'        = @{ situation = 'goal-new-material-decision';               expected = 'pause-for-decision' }
    'goal-budget-limited'           = @{ situation = 'goal-budget-reached';                      expected = 'no-auto-resume' }
    'release-preparation-goal'      = @{ situation = 'release-preparation';                      expected = 'goal-to-ready-for-release' }
    'alternative-comparison'        = @{ situation = 'independent-alternatives';                expected = 'multirun-isolated' }
    'unsafe-multirun'               = @{ situation = 'independent-alternatives';                expected = 'missing-multirun-precondition' }
    'release-boundary'              = @{ situation = 'release-action';                          expected = 'stop-for-approval' }
}

function Test-Phase8ScenarioSet {
    param(
        [object]$Scenarios,
        [string]$SourceLabel
    )

    $scenarioArray = @($Scenarios)
    if ($scenarioArray.Count -eq 0) {
        throw "$SourceLabel contains no scenarios; Phase 8 coverage must be non-empty."
    }

    $names = @($scenarioArray | ForEach-Object { [string]$_.name })
    foreach ($entry in $names) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            throw "$SourceLabel contains a scenario with an empty name."
        }
    }
    $duplicateNames = @($names | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($duplicateNames.Count -gt 0) {
        throw "$SourceLabel has duplicate scenario names: $($duplicateNames -join ', ')."
    }

    $requiredNames = @($requiredPhase8Scenarios.Keys)
    $missingNames = @($requiredNames | Where-Object { $_ -notin $names })
    if ($missingNames.Count -gt 0) {
        throw "$SourceLabel is missing required scenarios: $($missingNames -join ', ')."
    }
    $unexpectedNames = @($names | Where-Object { $_ -notin $requiredNames })
    if ($unexpectedNames.Count -gt 0) {
        throw "$SourceLabel has unexpected scenarios: $($unexpectedNames -join ', ')."
    }

    foreach ($scenario in $scenarioArray) {
        $requiredSpec = $requiredPhase8Scenarios[[string]$scenario.name]
        if ($null -eq $requiredSpec) {
            throw "$SourceLabel references an unknown scenario: '$($scenario.name)'."
        }
        if ([string]$scenario.situation -ne $requiredSpec.situation) {
            throw "$SourceLabel scenario '$($scenario.name)' has wrong situation. Expected '$($requiredSpec.situation)'; received '$($scenario.situation)'."
        }
        $actual = Get-AdvisoryVerdict -Scenario $scenario
        if ($actual -cne $requiredSpec.expected) {
            throw "$SourceLabel scenario '$($scenario.name)' got verdict '$actual'; expected '$($requiredSpec.expected)'."
        }
    }
}

$fixturePath = Join-Path $Root 'fixtures\phase-8\advisory-scenarios.json'
$guidePath = Join-Path $Root 'docs\openchamber-operating-guide.md'
$promptPath = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'
$presetPath = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$applyPath = Join-Path $Root 'scripts\Apply-OpenChamberOperatingGuide.ps1'

foreach ($path in @($fixturePath, $guidePath, $promptPath, $presetPath, $applyPath)) {
    Assert-True -Condition (Test-Path -LiteralPath $path) -Message "Required Phase 8 source not found: $path"
}

try {
    $scenarios = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
    $preset = Get-Content -LiteralPath $presetPath -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Invalid Phase 8 JSON source. $($_.Exception.Message)"
}

Test-Phase8ScenarioSet -Scenarios $scenarios -SourceLabel 'fixtures\phase-8/advisory-scenarios.json'

# Negative mutation: a fixture set with a duplicate scenario must be rejected.
$duplicateScenarios = @($scenarios) + @($scenarios | Select-Object -First 1)
$caughtDuplicate = $false
try {
    Test-Phase8ScenarioSet -Scenarios $duplicateScenarios -SourceLabel 'mutation:duplicate'
} catch {
    $caughtDuplicate = $true
}
Assert-True -Condition $caughtDuplicate -Message 'Phase 8 gate must reject a fixture set that contains a duplicate scenario name.'

# Negative mutation: a fixture set missing a required scenario must be rejected.
$missingScenarios = @($scenarios | Where-Object { [string]$_.name -ne 'small-question' })
$caughtMissing = $false
try {
    Test-Phase8ScenarioSet -Scenarios $missingScenarios -SourceLabel 'mutation:missing'
} catch {
    $caughtMissing = $true
}
Assert-True -Condition $caughtMissing -Message 'Phase 8 gate must reject a fixture set that is missing a required scenario.'

# Negative mutation: a scenario with an unknown situation must be rejected by Get-AdvisoryVerdict.
$mutatedScenarios = @($scenarios | ForEach-Object {
    if ([string]$_.name -eq 'small-question') {
        $clone = $_ | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $clone.situation = 'unknown-situation'
        return $clone
    }
    return $_
})
$mutatedTarget = @($mutatedScenarios | Where-Object { [string]$_.name -eq 'small-question' })[0]
$unknownVerdict = Get-AdvisoryVerdict -Scenario $mutatedTarget
Assert-True -Condition ($unknownVerdict -ceq 'unknown-situation') -Message 'Phase 8 gate must classify an unknown situation as unknown-situation.'

$guide = Get-Content -LiteralPath $guidePath -Raw
foreach ($rule in @('Choose The Smallest Mode', 'Adaptive Interview', 'Suggested Objective Template', 'Pause And Blocked Conditions', 'Goal In Release', 'ready for release', 'Evaluating', 'backgroundJobs.continueOnIdle', 'Folder And Project Memory Conventions', 'MultiRun')) {
    Assert-True -Condition $guide.Contains($rule) -Message "Operating guide is missing required rule: $rule"
}

$prompt = Get-Content -LiteralPath $promptPath -Raw
foreach ($rule in @('Give one brief', 'After every completed workflow step', 'Do not apply a fixed question count', 'writing work only', 'read-only deterministic work', 'ready for release', 'outside the Goal boundary', 'never arm, resume, change its budget', 'Evaluating', 'MultiRun', 'explicit user approval')) {
    Assert-True -Condition $prompt.Contains($rule) -Message "Orchestrator prompt is missing required Phase 8 rule: $rule"
}

Assert-True -Condition ($preset.backgroundJobs.continueOnIdle -eq $false) -Message 'Slim idle continuation must remain disabled; OpenChamber Session Goals are the sole continuation controller.'
Assert-True -Condition ($preset.disabled_skills -contains 'worktrees') -Message 'Slim worktree skill must remain disabled; OpenChamber owns worktrees.'

$apply = Get-Content -LiteralPath $applyPath -Raw
foreach ($rule in @('SupportsShouldProcess', 'openchamber|cpa|opencode', 'Get-FileHash', 'Copy-Item -LiteralPath $Target -Destination $backupPrompt', 'hash mismatch after apply', 'Copy-Item -LiteralPath $backupPrompt -Destination $Target')) {
    Assert-True -Condition $apply.Contains($rule) -Message "Phase 8 activation script is missing required safety rule: $rule"
}

'Phase 8 OpenChamber operating guide: PASS'
