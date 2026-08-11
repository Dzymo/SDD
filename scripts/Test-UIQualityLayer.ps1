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

function Get-UiQualityVerdict {
    param([object]$Scenario)

    if ($Scenario.proof -eq 'synthetic-score') {
        return 'SYNTHETIC-SCORE-REJECTED'
    }

    if ($Scenario.authority.product -ne 'present' -or
        $Scenario.authority.design -ne 'present' -or
        $Scenario.authority.surfaceBrief -ne 'approved' -or
        $Scenario.authority.fidelity -ne 'preserved') {
        return 'MISSING-OR-DISREGARDED-AUTHORITY'
    }

    foreach ($checkName in @('desktop', 'mobile', 'browser', 'accessibility')) {
        $check = $Scenario.machineChecks.$checkName
        if ($null -eq $check -or [string]::IsNullOrWhiteSpace($check.evidence)) {
            return 'MISSING-MACHINE-EVIDENCE'
        }
        if ($check.exitCode -ne 0) {
            return 'FAILED-MACHINE-CHECK'
        }
    }

    if ($Scenario.review.independent -ne $true -or
        [string]::IsNullOrWhiteSpace($Scenario.review.desktopScreenshot) -or
        [string]::IsNullOrWhiteSpace($Scenario.review.mobileScreenshot) -or
        $Scenario.review.status -ne 'closed') {
        return 'MISSING-INDEPENDENT-SCREENSHOT-REVIEW'
    }

    if ($Scenario.humanApproval -eq 'approved') {
        return 'UI-APPROVED'
    }
    return 'READY-FOR-HUMAN-APPROVAL'
}

# Verdict expectations and fixed scenario coverage are owned by code.
$requiredPhase9Scenarios = [ordered]@{
    'selected-direction-awaits-human-approval'  = @{ expected = 'READY-FOR-HUMAN-APPROVAL' }
    'selected-direction-has-explicit-human-approval' = @{ expected = 'UI-APPROVED' }
    'synthetic-score-is-not-proof'               = @{ expected = 'SYNTHETIC-SCORE-REJECTED' }
    'missing-mobile-evidence-cannot-reach-review' = @{ expected = 'MISSING-MACHINE-EVIDENCE' }
}

function Test-Phase9ScenarioSet {
    param(
        [object]$Scenarios,
        [string]$SourceLabel
    )

    $scenarioArray = @($Scenarios)
    if ($scenarioArray.Count -eq 0) {
        throw "$SourceLabel contains no scenarios; Phase 9 coverage must be non-empty."
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

    $requiredNames = @($requiredPhase9Scenarios.Keys)
    $missingNames = @($requiredNames | Where-Object { $_ -notin $names })
    if ($missingNames.Count -gt 0) {
        throw "$SourceLabel is missing required scenarios: $($missingNames -join ', ')."
    }
    $unexpectedNames = @($names | Where-Object { $_ -notin $requiredNames })
    if ($unexpectedNames.Count -gt 0) {
        throw "$SourceLabel has unexpected scenarios: $($unexpectedNames -join ', ')."
    }

    foreach ($scenario in $scenarioArray) {
        $name = [string]$scenario.name
        $requiredSpec = $requiredPhase9Scenarios[$name]
        if ($null -eq $requiredSpec) {
            throw "$SourceLabel references an unknown scenario: '$name'."
        }
        $actual = Get-UiQualityVerdict -Scenario $scenario
        if ($actual -cne $requiredSpec.expected) {
            throw "$SourceLabel scenario '$name' got verdict '$actual'; expected '$($requiredSpec.expected)'."
        }
    }
}

$fixturePath = Join-Path $Root 'fixtures\phase-9\ui-review-scenarios.json'
$guidePath = Join-Path $Root 'docs\ui-quality-layer.md'
$skillPath = Join-Path $Root 'skills\ui-quality\SKILL.md'
$designerPromptPath = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\designer.md'
$observerPromptPath = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\observer.md'
$surfaceTemplatePath = Join-Path $Root 'templates\project\docs\surfaces\README.md'
$presetPath = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$applyPath = Join-Path $Root 'scripts\Apply-UIQualityLayer.ps1'
$runtimePath = Join-Path $Root 'scripts\Test-UIQualityLayerRuntime.ps1'

foreach ($path in @($fixturePath, $guidePath, $skillPath, $designerPromptPath, $observerPromptPath, $surfaceTemplatePath, $presetPath, $applyPath, $runtimePath)) {
    Assert-True -Condition (Test-Path -LiteralPath $path) -Message "Required Phase 9 source not found: $path"
}

try {
    $scenarios = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
    $preset = Get-Content -LiteralPath $presetPath -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Invalid Phase 9 JSON source. $($_.Exception.Message)"
}

Test-Phase9ScenarioSet -Scenarios $scenarios -SourceLabel 'fixtures/phase-9/ui-review-scenarios.json'

# Negative mutation: duplicate scenario names must be rejected.
$duplicateScenarios = @($scenarios) + @($scenarios | Select-Object -First 1)
$caughtDuplicate = $false
try {
    Test-Phase9ScenarioSet -Scenarios $duplicateScenarios -SourceLabel 'mutation:duplicate'
} catch {
    $caughtDuplicate = $true
}
Assert-True -Condition $caughtDuplicate -Message 'Phase 9 gate must reject a fixture set that contains a duplicate scenario name.'

# Negative mutation: a fixture set missing a required scenario must be rejected.
$missingScenarios = @($scenarios | Where-Object { [string]$_.name -ne 'synthetic-score-is-not-proof' })
$caughtMissing = $false
try {
    Test-Phase9ScenarioSet -Scenarios $missingScenarios -SourceLabel 'mutation:missing'
} catch {
    $caughtMissing = $true
}
Assert-True -Condition $caughtMissing -Message 'Phase 9 gate must reject a fixture set that is missing a required scenario.'

# Negative mutation: a scenario claiming synthetic-score proof must be rejected even when other fields are present.
$sourceForMutation = @($scenarios | Where-Object { [string]$_.name -eq 'selected-direction-has-explicit-human-approval' })[0]
$mutationJson = $sourceForMutation | ConvertTo-Json -Depth 10
$mutatedJson = $mutationJson -replace '"name":\s*"selected-direction-has-explicit-human-approval"', '"name": "synthetic-score-mutation", "proof": "synthetic-score"'
$clone = $mutatedJson | ConvertFrom-Json
$mutatedVerdict = Get-UiQualityVerdict -Scenario $clone
Assert-True -Condition ($mutatedVerdict -ceq 'SYNTHETIC-SCORE-REJECTED') -Message 'Phase 9 gate must reject a record that claims a synthetic score, even when other authorities are present.'

Assert-True -Condition ($preset.presets.'sdd-personal'.designer.skills -contains 'ui-quality') -Message 'Designer must load the ui-quality skill.'

$requiredContent = @{
    $guidePath = @('Authority Order', 'PRODUCT.md', 'DESIGN.md', 'manageable comparison', 'without a fixed question or round count', 'Surface Brief', 'Desktop And Mobile', 'Browser And Accessibility', 'Independent Screenshot Review', 'not proof')
    $skillPath = @('`PRODUCT.md` owns', '`DESIGN.md` owns', 'manageable comparison', 'Do not impose a fixed question', 'Machine checks establish readiness for review', 'explicit user visual approval')
    $designerPromptPath = @('Authority Order', 'Interview adaptively', 'Impeccable detector', 'synthetic quality scores', 'fresh independent screenshot review')
    $observerPromptPath = @('Independent UI Review', 'synthetic score', 'user visual approval')
    $surfaceTemplatePath = @('PRODUCT.md', 'DESIGN.md', 'Approved Direction', 'not final visual approval')
    $applyPath = @('SupportsShouldProcess', 'Get-FileHashOrAbsent', 'Write-JsonUtf8NoBom', 'UTF8Encoding]::new($false)', 'Close OpenChamber and CPA GUI', 'Phase 9 apply failed and changed targets were restored')
    $runtimePath = @('debug', 'Authority Order', '"permission": "skill"', '"pattern": "ui-quality"', 'Independent UI Review')
}

foreach ($path in $requiredContent.Keys) {
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($rule in $requiredContent[$path]) {
        Assert-True -Condition $content.Contains($rule) -Message "$path is missing required Phase 9 rule: $rule"
    }
}

'Phase 9 UI quality layer: PASS'
