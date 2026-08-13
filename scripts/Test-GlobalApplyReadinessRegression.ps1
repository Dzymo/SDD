[CmdletBinding()]
param(
    [string]$Root
)

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) {
        throw $Message
    }
}

function New-TestFrameworkCopy {
    param([string]$Root)

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ga-01-framework-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $tempRoot -Force -ErrorAction Stop | Out-Null

    $configSourceDir = Join-Path $tempRoot 'config'
    New-Item -ItemType Directory -Path (Join-Path $configSourceDir 'opencode') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $configSourceDir 'oh-my-opencode-slim') -Force -ErrorAction Stop | Out-Null
    $promptsSourceDir = Join-Path $tempRoot 'prompts\oh-my-opencode-slim\sdd-personal'
    New-Item -ItemType Directory -Path $promptsSourceDir -Force -ErrorAction Stop | Out-Null
    $skillsSourceDir = Join-Path $tempRoot 'skills'
    New-Item -ItemType Directory -Path $skillsSourceDir -Force -ErrorAction Stop | Out-Null

    Copy-Item -LiteralPath (Join-Path $Root 'config\opencode\research-mcp.json') -Destination (Join-Path $configSourceDir 'opencode\research-mcp.json') -ErrorAction Stop
    Copy-Item -LiteralPath (Join-Path $Root 'config\opencode\research-references.json') -Destination (Join-Path $configSourceDir 'opencode\research-references.json') -ErrorAction Stop
    Copy-Item -LiteralPath (Join-Path $Root 'config\opencode\agent-layer.plugin.json') -Destination (Join-Path $configSourceDir 'opencode\agent-layer.plugin.json') -ErrorAction Stop
    Copy-Item -LiteralPath (Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json') -Destination (Join-Path $configSourceDir 'oh-my-opencode-slim\sdd-personal.json') -ErrorAction Stop

    foreach ($agent in @('orchestrator', 'explorer', 'librarian', 'fixer', 'oracle', 'designer', 'observer')) {
        $source = Join-Path $Root "prompts\oh-my-opencode-slim\sdd-personal\$agent.md"
        $destination = Join-Path $promptsSourceDir "$agent.md"
        Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
    }

    New-Item -ItemType Directory -Path (Join-Path $skillsSourceDir 'source-first-research') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $skillsSourceDir 'systematic-debugging') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $skillsSourceDir 'verification-before-completion') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $skillsSourceDir 'ui-quality') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $skillsSourceDir 'package-and-release') -Force -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root 'skills\source-first-research\SKILL.md') -Destination (Join-Path $skillsSourceDir 'source-first-research\SKILL.md') -ErrorAction Stop
    Copy-Item -LiteralPath (Join-Path $Root 'skills\systematic-debugging\SKILL.md') -Destination (Join-Path $skillsSourceDir 'systematic-debugging\SKILL.md') -ErrorAction Stop
    Copy-Item -LiteralPath (Join-Path $Root 'skills\verification-before-completion\SKILL.md') -Destination (Join-Path $skillsSourceDir 'verification-before-completion\SKILL.md') -ErrorAction Stop
    Copy-Item -LiteralPath (Join-Path $Root 'skills\ui-quality\SKILL.md') -Destination (Join-Path $skillsSourceDir 'ui-quality\SKILL.md') -ErrorAction Stop
    Copy-Item -LiteralPath (Join-Path $Root 'skills\package-and-release\SKILL.md') -Destination (Join-Path $skillsSourceDir 'package-and-release\SKILL.md') -ErrorAction Stop

    & git -C $tempRoot init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the temporary readiness candidate repository.' }
    & git -C $tempRoot add --all
    if ($LASTEXITCODE -ne 0) { throw 'Could not stage the temporary readiness candidate.' }
    & git -C $tempRoot -c user.name='SDD Readiness Test' -c user.email='readiness@example.invalid' commit --quiet -m 'Create readiness fixture'
    if ($LASTEXITCODE -ne 0) { throw 'Could not commit the temporary readiness candidate.' }

    return $tempRoot
}

function New-TestManagedRoot {
    param(
        [string]$Parent,
        [string]$Name,
        [string]$FrameworkRoot
    )

    $caseRoot = Join-Path $Parent $Name
    New-Item -ItemType Directory -Path $caseRoot -Force -ErrorAction Stop | Out-Null
    $openCodeRoot = Join-Path $caseRoot 'opencode'
    New-Item -ItemType Directory -Path (Join-Path $openCodeRoot 'oh-my-opencode-slim\sdd-personal') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $openCodeRoot 'skills') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $openCodeRoot 'skills\source-first-research') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $openCodeRoot 'skills\systematic-debugging') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $openCodeRoot 'skills\verification-before-completion') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $openCodeRoot 'skills\ui-quality') -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $openCodeRoot 'skills\package-and-release') -Force -ErrorAction Stop | Out-Null

    $configSource = Join-Path $FrameworkRoot 'config\oh-my-opencode-slim\sdd-personal.json'
    $mergedConfig = Get-Content -LiteralPath $configSource -Raw | ConvertFrom-Json

    $opencodeConfig = [ordered]@{
        '$schema' = 'https://opencode.ai/config.json'
        plugin = @('oh-my-opencode-slim@2.2.8')
        mcp = [ordered]@{
            context7 = [ordered]@{
                type = 'remote'
                url = 'https://mcp.context7.com/mcp/oauth'
                enabled = $true
            }
            codegraph = [ordered]@{
                type = 'local'
                command = @('codegraph', 'serve', '--mcp')
                enabled = $true
            }
        }
        references = [ordered]@{
            codegraph = [ordered]@{
                path = 'D:\Projects\Docs\codegraph'
                description = 'Local CodeGraph source for exact implementation evidence.'
                hidden = $true
            }
        }
        unrelated = [ordered]@{
            preserved = $true
        }
    }
    $opencodeConfigPath = Join-Path $openCodeRoot 'opencode.jsonc'
    $opencodeConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $opencodeConfigPath -Encoding Ascii

    $pluginTargetPath = Join-Path $openCodeRoot 'oh-my-opencode-slim.json'
    $mergedConfig | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $pluginTargetPath -Encoding Ascii

    $promptTargets = @(
        'orchestrator', 'explorer', 'librarian', 'fixer', 'oracle', 'designer', 'observer'
    )
    foreach ($agent in $promptTargets) {
        $source = Join-Path $FrameworkRoot "prompts\oh-my-opencode-slim\sdd-personal\$agent.md"
        $destination = Join-Path $openCodeRoot "oh-my-opencode-slim\sdd-personal\$agent.md"
        Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
    }

    $skillTargets = @(
        @{ Source = 'source-first-research\SKILL.md'; Target = 'skills\source-first-research\SKILL.md' },
        @{ Source = 'systematic-debugging\SKILL.md'; Target = 'skills\systematic-debugging\SKILL.md' },
        @{ Source = 'verification-before-completion\SKILL.md'; Target = 'skills\verification-before-completion\SKILL.md' },
        @{ Source = 'ui-quality\SKILL.md'; Target = 'skills\ui-quality\SKILL.md' },
        @{ Source = 'package-and-release\SKILL.md'; Target = 'skills\package-and-release\SKILL.md' }
    )
    foreach ($pair in $skillTargets) {
        $source = Join-Path $FrameworkRoot "skills\$($pair.Source)"
        $destination = Join-Path $openCodeRoot $pair.Target
        Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
    }

    return @{
        CaseRoot = $caseRoot
        OpenCodeRoot = $openCodeRoot
        OpencodeConfigPath = $opencodeConfigPath
        PluginTargetPath = $pluginTargetPath
    }
}

$script:InvocationCount = 0
function Invoke-Preflight {
    param(
        [string]$Root,
        [string]$OpenCodeRoot,
        [string]$PhaseFivePackagePath,
        [string]$PhaseFiveExpectedHash,
        [string[]]$SimulatedProcessNames,
        [switch]$SimulatedDirty,
        [object[]]$AdditionalTargets,
        [string]$OutputPath,
        [switch]$ExpectThrow
    )

    $arguments = @{
        Root = $Root
        OpenCodeRoot = $OpenCodeRoot
        PhaseFivePackagePath = $PhaseFivePackagePath
        PhaseFiveExpectedHash = $PhaseFiveExpectedHash
    }
    if ($null -ne $SimulatedProcessNames) { $arguments['SimulatedProcessNames'] = $SimulatedProcessNames }
    if ($SimulatedDirty) { $arguments['SimulatedDirty'] = [switch]$SimulatedDirty }
    if ($AdditionalTargets) { $arguments['AdditionalTargets'] = $AdditionalTargets }

    $reportPath = if ($OutputPath) {
        $arguments['OutputPath'] = $OutputPath
        $OutputPath
    }
    else {
        $script:InvocationCount += 1
        $invokePath = Join-Path $tempParent "invoke-$('{0:D3}' -f $script:InvocationCount).json"
        if (Test-Path -LiteralPath $invokePath -PathType Leaf) {
            Remove-Item -LiteralPath $invokePath -Force -ErrorAction Stop
        }
        $arguments['OutputPath'] = $invokePath
        $invokePath
    }

    if ($ExpectThrow) {
        $output = & (Join-Path $PSScriptRoot 'Test-GlobalApplyReadiness.ps1') @arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
        throw "Preflight did not throw when expected. ExitCode=$exitCode Output=$output"
    }

    $output = & (Join-Path $PSScriptRoot 'Test-GlobalApplyReadiness.ps1') @arguments 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json -ErrorAction Stop

    return [pscustomobject]@{
        ExitCode = $exitCode
        Report = $report
        Output = $output
        ReportPath = $reportPath
    }
}

function Find-TargetReport {
    param(
        [object]$Report,
        [string]$Name
    )

    return @($Report.targets | Where-Object { $_.name -eq $Name })[0]
}

$preflightScript = Join-Path $PSScriptRoot 'Test-GlobalApplyReadiness.ps1'
Assert-True -Condition (Test-Path -LiteralPath $preflightScript -PathType Leaf) -Message "Preflight script is missing: $preflightScript"

$tempParent = Join-Path ([System.IO.Path]::GetTempPath()) "ga-01-readiness-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tempParent -Force -ErrorAction Stop | Out-Null

$phaseFiveRoot = Join-Path $tempParent 'phase5'
New-Item -ItemType Directory -Path (Join-Path $phaseFiveRoot 'dist') -Force -ErrorAction Stop | Out-Null
$phaseFivePackagePath = Join-Path $phaseFiveRoot 'dist\index.js'
$phaseFiveExpectedHash = '111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF0000'
[System.IO.File]::WriteAllText($phaseFivePackagePath, 'phase5-mock', [System.Text.Encoding]::ASCII)
$phaseFiveActualHash = (Get-FileHash -LiteralPath $phaseFivePackagePath -Algorithm SHA256).Hash
$phaseFiveWrongHash = '0000000000000000000000000000000000000000000000000000000000000000'

try {
    $frameworkRoot = New-TestFrameworkCopy -Root $Root

    $allMatchCase = New-TestManagedRoot -Parent $tempParent -Name 'all-match' -FrameworkRoot $frameworkRoot
    $allMatchResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $allMatchCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @()
    'Scenario all-match: exit=' + $allMatchResult.ExitCode + ' verdict=' + $allMatchResult.Report.verdict.value
    Assert-True -Condition ($allMatchResult.ExitCode -eq 0) -Message "All-match scenario did not exit 0.`n$($allMatchResult.Output)"
    Assert-True -Condition ($allMatchResult.Report.verdict.value -eq 'NO_APPLY_REQUIRED') -Message "All-match scenario did not report NO_APPLY_REQUIRED. Got: $($allMatchResult.Report.verdict.value). Reasons: $($allMatchResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ($allMatchResult.Report.verdict.applyPreconditionSatisfied -eq $true) -Message "All-match scenario did not report applyPreconditionSatisfied=true. Got: $($allMatchResult.Report.verdict.applyPreconditionSatisfied)"
    $allMatchTargets = @($allMatchResult.Report.targets)
    Assert-True -Condition ($allMatchTargets.Count -eq 14) -Message "All-match scenario did not report all 14 framework-owned targets. Reported: $($allMatchTargets.Count)"
    foreach ($target in $allMatchTargets) {
        Assert-True -Condition ($target.match -eq 'MATCH') -Message "All-match scenario reported a non-MATCH target: $($target.name) -> $($target.match)"
        Assert-True -Condition ($target.support -eq 'SUPPORTED') -Message "All-match scenario reported an unsupported target: $($target.name) -> $($target.support)"
        Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($target.owner)) -Message "All-match target missing owner: $($target.name)"
        Assert-True -Condition ($target.verifiers.Count -gt 0) -Message "All-match target missing verifiers: $($target.name)"
        Assert-True -Condition ($target.rollbackSupported -eq $true) -Message "All-match target missing rollbackSupported=true: $($target.name)"
        Assert-True -Condition ($null -ne $target.comparisonMetadata) -Message "All-match target missing comparisonMetadata: $($target.name)"
    }
    $orchestratorCount = @($allMatchTargets | Where-Object { $_.name -eq 'orchestrator.md' }).Count
    Assert-True -Condition ($orchestratorCount -eq 1) -Message "All-match scenario reported orchestrator.md $orchestratorCount times; expected once."
    $orchestratorTarget = @($allMatchTargets | Where-Object { $_.name -eq 'orchestrator.md' })[0]
    Assert-True -Condition ($orchestratorTarget.phase -eq '7, 8, 10') -Message "Orchestrator target phase metadata is incomplete: $($orchestratorTarget.phase)"
    Assert-True -Condition ($orchestratorTarget.applyScripts -contains 'Apply-ExecutionVerification.ps1') -Message 'Orchestrator target metadata must include the Phase 7 apply script.'
    Assert-True -Condition ($orchestratorTarget.verifiers -contains 'Test-ExecutionVerificationRuntime.ps1') -Message 'Orchestrator target metadata must include the Phase 7 runtime verifier.'
    Assert-True -Condition ($allMatchResult.Report.phaseFivePackage.match -eq 'MATCH') -Message "All-match scenario did not report Phase 5 MATCH."
    Assert-True -Condition ($allMatchResult.Report.processState.blocked -eq $false) -Message "All-match scenario reported blocked processes when none were simulated."

    $unrelatedConfig = Get-Content -LiteralPath $allMatchCase.OpencodeConfigPath -Raw | ConvertFrom-Json
    $unrelatedConfig.mcp | Add-Member -NotePropertyName userOwned -NotePropertyValue ([pscustomobject]@{ enabled = $true }) -Force
    $unrelatedConfig.references | Add-Member -NotePropertyName userOwned -NotePropertyValue ([pscustomobject]@{ path = 'D:\User\Reference' }) -Force
    $unrelatedConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $allMatchCase.OpencodeConfigPath -Encoding Ascii
    $unrelatedResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $allMatchCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @()
    'Scenario unrelated-config: exit=' + $unrelatedResult.ExitCode + ' verdict=' + $unrelatedResult.Report.verdict.value
    Assert-True -Condition ($unrelatedResult.ExitCode -eq 0) -Message "Unrelated-config scenario did not exit 0.`n$($unrelatedResult.Output)"
    Assert-True -Condition ($unrelatedResult.Report.verdict.value -eq 'NO_APPLY_REQUIRED') -Message "Unrelated user-owned config was incorrectly classified as drift. Got: $($unrelatedResult.Report.verdict.value)."

    $driftCase = New-TestManagedRoot -Parent $tempParent -Name 'supported-drift' -FrameworkRoot $frameworkRoot
    $driftTargetPath = Join-Path $driftCase.OpenCodeRoot 'skills\ui-quality\SKILL.md'
    [System.IO.File]::WriteAllText($driftTargetPath, 'stale-content-for-drift-test', [System.Text.Encoding]::ASCII)
    $driftSourcePath = Join-Path $frameworkRoot 'skills\ui-quality\SKILL.md'
    Assert-True -Condition ((Get-FileHash -LiteralPath $driftTargetPath -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $driftSourcePath -Algorithm SHA256).Hash) -Message 'Drift scenario setup did not produce different hashes.'
    $driftResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $driftCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @()
    'Scenario supported-drift: exit=' + $driftResult.ExitCode + ' verdict=' + $driftResult.Report.verdict.value
    Assert-True -Condition ($driftResult.ExitCode -eq 0) -Message "Supported-drift scenario did not exit 0.`n$($driftResult.Output)"
    Assert-True -Condition ($driftResult.Report.verdict.value -eq 'READY_FOR_GLOBAL_APPLY') -Message "Supported-drift scenario did not report READY_FOR_GLOBAL_APPLY. Got: $($driftResult.Report.verdict.value). Reasons: $($driftResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ($driftResult.Report.verdict.applyPreconditionSatisfied -eq $true) -Message "Supported-drift scenario did not report applyPreconditionSatisfied=true. Got: $($driftResult.Report.verdict.applyPreconditionSatisfied)"
    $driftTargetReport = Find-TargetReport -Report $driftResult.Report -Name 'ui-quality.SKILL.md'
    Assert-True -Condition ($driftTargetReport.match -eq 'DRIFT') -Message "Supported-drift scenario did not classify ui-quality.SKILL.md as DRIFT."
    Assert-True -Condition ($driftTargetReport.support -eq 'SUPPORTED') -Message "Supported-drift scenario did not classify ui-quality.SKILL.md as SUPPORTED."

    $missingCase = New-TestManagedRoot -Parent $tempParent -Name 'missing-target' -FrameworkRoot $frameworkRoot
    $missingTargetPath = Join-Path $missingCase.OpenCodeRoot 'skills\package-and-release\SKILL.md'
    if (Test-Path -LiteralPath $missingTargetPath -PathType Leaf) {
        Remove-Item -LiteralPath $missingTargetPath -Force -ErrorAction Stop
    }
    $missingResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $missingCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @()
    'Scenario missing-target: exit=' + $missingResult.ExitCode + ' verdict=' + $missingResult.Report.verdict.value
    Assert-True -Condition ($missingResult.ExitCode -ne 0) -Message "Missing-target scenario did not block exit. Output:`n$($missingResult.Output)"
    Assert-True -Condition ($missingResult.Report.verdict.value -eq 'BLOCKED') -Message "Missing-target scenario did not report BLOCKED. Got: $($missingResult.Report.verdict.value). Reasons: $($missingResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ([bool]($missingResult.Report.verdict.reasons -match 'package-and-release.SKILL.md')) -Message "Missing-target scenario did not mention the absent target by name. Reasons: $($missingResult.Report.verdict.reasons -join ' | ')"
    $missingTargetReport = Find-TargetReport -Report $missingResult.Report -Name 'package-and-release.SKILL.md'
    Assert-True -Condition ($missingTargetReport.match -eq 'ABSENT') -Message "Missing-target scenario did not classify package-and-release.SKILL.md as ABSENT. Got: $($missingTargetReport.match)"

    $unsupportedCase = New-TestManagedRoot -Parent $tempParent -Name 'unsupported-drift' -FrameworkRoot $frameworkRoot
    $unsupportedTarget = @{
        Name = 'unsupported-experiment.md'
        Phase = 'experimental'
        Owner = 'User-installed'
        RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\unsupported-experiment.md'
        RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'
        ComparisonType = 'raw'
        ApplyScripts = @()
        Verifiers = @()
        RollbackSupported = $false
        ManagedSourceKey = $null
        MergeSpec = @()
    }
    [System.IO.File]::WriteAllText((Join-Path $unsupportedCase.OpenCodeRoot 'oh-my-opencode-slim\sdd-personal\unsupported-experiment.md'), 'user-installed-but-not-framework-owned', [System.Text.Encoding]::ASCII)
    $unsupportedResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $unsupportedCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @() -AdditionalTargets @($unsupportedTarget)
    'Scenario unsupported-drift: exit=' + $unsupportedResult.ExitCode + ' verdict=' + $unsupportedResult.Report.verdict.value
    Assert-True -Condition ($unsupportedResult.ExitCode -ne 0) -Message "Unsupported-drift scenario did not block exit.`n$($unsupportedResult.Output)"
    Assert-True -Condition ($unsupportedResult.Report.verdict.value -eq 'BLOCKED') -Message "Unsupported-drift scenario did not report BLOCKED. Got: $($unsupportedResult.Report.verdict.value). Reasons: $($unsupportedResult.Report.verdict.reasons -join ' | ')"
    $unsupportedReport = Find-TargetReport -Report $unsupportedResult.Report -Name 'unsupported-experiment.md'
    Assert-True -Condition ($null -ne $unsupportedReport) -Message 'Unsupported-drift scenario did not report the additional target.'
    Assert-True -Condition ($unsupportedReport.match -eq 'DRIFT') -Message "Unsupported-drift scenario did not classify additional target as DRIFT."
    Assert-True -Condition ($unsupportedReport.support -eq 'UNSUPPORTED') -Message "Unsupported-drift scenario did not classify additional target as UNSUPPORTED."

    $pluginDriftCase = New-TestManagedRoot -Parent $tempParent -Name 'plugin-drift' -FrameworkRoot $frameworkRoot
    $pluginDriftConfig = Get-Content -LiteralPath $pluginDriftCase.OpencodeConfigPath -Raw | ConvertFrom-Json
    $pluginDriftConfig.plugin = @('oh-my-opencode-slim@2.2.8', 'unwanted-plugin@9.9.9')
    $pluginDriftConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $pluginDriftCase.OpencodeConfigPath -Encoding Ascii
    $pluginDriftResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $pluginDriftCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @()
    'Scenario plugin-drift: exit=' + $pluginDriftResult.ExitCode + ' verdict=' + $pluginDriftResult.Report.verdict.value
    Assert-True -Condition ($pluginDriftResult.ExitCode -ne 0) -Message "Plugin-drift scenario did not block exit.`n$($pluginDriftResult.Output)"
    Assert-True -Condition ($pluginDriftResult.Report.verdict.value -eq 'BLOCKED') -Message "Plugin-drift scenario did not report BLOCKED. Got: $($pluginDriftResult.Report.verdict.value). Reasons: $($pluginDriftResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ([bool]($pluginDriftResult.Report.verdict.reasons -match 'plugin')) -Message "Plugin-drift scenario did not mention the plugin field in reasons. Reasons: $($pluginDriftResult.Report.verdict.reasons -join ' | ')"
    $pluginDriftReport = Find-TargetReport -Report $pluginDriftResult.Report -Name 'opencode.jsonc'
    Assert-True -Condition ($pluginDriftReport.match -eq 'DRIFT') -Message "Plugin-drift scenario did not classify opencode.jsonc as DRIFT."
    Assert-True -Condition ($pluginDriftReport.support -eq 'UNSUPPORTED') -Message "Plugin-drift scenario did not classify opencode.jsonc as UNSUPPORTED."

    $dirtyCase = New-TestManagedRoot -Parent $tempParent -Name 'dirty-candidate' -FrameworkRoot $frameworkRoot
    $dirtyResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $dirtyCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @() -SimulatedDirty
    'Scenario dirty-candidate: exit=' + $dirtyResult.ExitCode + ' verdict=' + $dirtyResult.Report.verdict.value
    Assert-True -Condition ($dirtyResult.ExitCode -ne 0) -Message "Dirty-candidate scenario did not block exit.`n$($dirtyResult.Output)"
    Assert-True -Condition ($dirtyResult.Report.verdict.value -eq 'BLOCKED') -Message "Dirty-candidate scenario did not report BLOCKED. Got: $($dirtyResult.Report.verdict.value). Reasons: $($dirtyResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ($dirtyResult.Report.candidate.clean -eq $false) -Message 'Dirty-candidate scenario did not report candidate.clean=false.'

    $processAllMatchCase = New-TestManagedRoot -Parent $tempParent -Name 'process-all-match' -FrameworkRoot $frameworkRoot
    $processAllMatchResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $processAllMatchCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @('opencode')
    'Scenario process-all-match: exit=' + $processAllMatchResult.ExitCode + ' verdict=' + $processAllMatchResult.Report.verdict.value
    Assert-True -Condition ($processAllMatchResult.ExitCode -eq 0) -Message "Active-process all-match scenario did not exit 0.`n$($processAllMatchResult.Output)"
    Assert-True -Condition ($processAllMatchResult.Report.verdict.value -eq 'NO_APPLY_REQUIRED') -Message "Active-process all-match scenario did not report NO_APPLY_REQUIRED. Got: $($processAllMatchResult.Report.verdict.value). Reasons: $($processAllMatchResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ($processAllMatchResult.Report.verdict.applyPreconditionSatisfied -eq $false) -Message "Active-process all-match scenario did not report applyPreconditionSatisfied=false. Got: $($processAllMatchResult.Report.verdict.applyPreconditionSatisfied)"
    Assert-True -Condition ($processAllMatchResult.Report.processState.blocked -eq $true) -Message 'Active-process all-match scenario did not report blocked processes.'
    Assert-True -Condition ($processAllMatchResult.Report.candidate.clean -eq $true) -Message 'Active-process all-match scenario did not use a clean candidate.'
    Assert-True -Condition ([string]$processAllMatchResult.Report.candidate.sha -match '^[0-9a-f]{40}$') -Message "Active-process all-match scenario did not use an immutable Git SHA. Got: $($processAllMatchResult.Report.candidate.sha)"

    $processDriftCase = New-TestManagedRoot -Parent $tempParent -Name 'process-drift' -FrameworkRoot $frameworkRoot
    $processDriftTargetPath = Join-Path $processDriftCase.OpenCodeRoot 'skills\source-first-research\SKILL.md'
    [System.IO.File]::WriteAllText($processDriftTargetPath, 'stale-content-with-process', [System.Text.Encoding]::ASCII)
    $processDriftResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $processDriftCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @('openchamber', 'cpa', 'opencode')
    'Scenario process-drift: exit=' + $processDriftResult.ExitCode + ' verdict=' + $processDriftResult.Report.verdict.value
    Assert-True -Condition ($processDriftResult.ExitCode -ne 0) -Message "Active-process supported-drift scenario did not block exit.`n$($processDriftResult.Output)"
    Assert-True -Condition ($processDriftResult.Report.verdict.value -eq 'BLOCKED') -Message "Active-process supported-drift scenario did not report BLOCKED. Got: $($processDriftResult.Report.verdict.value). Reasons: $($processDriftResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ([bool]($processDriftResult.Report.verdict.reasons -match 'openchamber|cpa|opencode|process')) -Message "Active-process supported-drift scenario did not mention active processes. Reasons: $($processDriftResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ($processDriftResult.Report.processState.running.Count -eq 3) -Message "Active-process supported-drift scenario did not report three running processes. Got: $($processDriftResult.Report.processState.running.Count)"
    $processDriftTargetReport = Find-TargetReport -Report $processDriftResult.Report -Name 'source-first-research.SKILL.md'
    Assert-True -Condition ($processDriftTargetReport.match -eq 'DRIFT') -Message 'Active-process supported-drift scenario did not classify source-first-research.SKILL.md as DRIFT.'
    Assert-True -Condition ($processDriftTargetReport.support -eq 'SUPPORTED') -Message 'Active-process supported-drift scenario did not classify source-first-research.SKILL.md as SUPPORTED.'

    $phaseFiveDriftCase = New-TestManagedRoot -Parent $tempParent -Name 'phase5-drift' -FrameworkRoot $frameworkRoot
    $phaseFiveDriftResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $phaseFiveDriftCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveWrongHash -SimulatedProcessNames @()
    'Scenario phase5-drift: exit=' + $phaseFiveDriftResult.ExitCode + ' verdict=' + $phaseFiveDriftResult.Report.verdict.value
    Assert-True -Condition ($phaseFiveDriftResult.ExitCode -ne 0) -Message "Phase-5-drift scenario did not block exit.`n$($phaseFiveDriftResult.Output)"
    Assert-True -Condition ($phaseFiveDriftResult.Report.verdict.value -eq 'BLOCKED') -Message "Phase-5-drift scenario did not report BLOCKED. Got: $($phaseFiveDriftResult.Report.verdict.value). Reasons: $($phaseFiveDriftResult.Report.verdict.reasons -join ' | ')"
    Assert-True -Condition ($phaseFiveDriftResult.Report.phaseFivePackage.match -eq 'DRIFT') -Message 'Phase-5-drift scenario did not report Phase 5 DRIFT.'

    $outputParent = Join-Path $tempParent 'output'
    New-Item -ItemType Directory -Path $outputParent -Force -ErrorAction Stop | Out-Null
    $outputPath = Join-Path $outputParent 'preflight-report.json'
    $outputCase = New-TestManagedRoot -Parent $tempParent -Name 'output-path' -FrameworkRoot $frameworkRoot
    $outputResult = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $outputCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @() -OutputPath $outputPath
    'Scenario output-path: exit=' + $outputResult.ExitCode + ' verdict=' + $outputResult.Report.verdict.value
    Assert-True -Condition (Test-Path -LiteralPath $outputPath -PathType Leaf) -Message "OutputPath scenario did not create report file at $outputPath."
    $reportJson = Get-Content -LiteralPath $outputPath -Raw
    Assert-True -Condition ($reportJson.Length -gt 0) -Message 'OutputPath scenario wrote an empty report.'
    $reportObj = $reportJson | ConvertFrom-Json -ErrorAction Stop
    Assert-True -Condition ($reportObj.verdict.value -eq 'NO_APPLY_REQUIRED') -Message "OutputPath scenario report did not contain NO_APPLY_REQUIRED. Got: $($reportObj.verdict.value)"
    Assert-True -Condition (-not ($reportJson -match 'token|secret|password|api[_-]?key')) -Message 'OutputPath scenario wrote an unsanitized report.'

    $missingParent = Join-Path $tempParent 'absent-parent\report.json'
    $missingParentCase = New-TestManagedRoot -Parent $tempParent -Name 'output-path-absent-parent' -FrameworkRoot $frameworkRoot
    $absentParentError = $null
    try {
        $null = Invoke-Preflight -Root $frameworkRoot -OpenCodeRoot $missingParentCase.OpenCodeRoot -PhaseFivePackagePath $phaseFivePackagePath -PhaseFiveExpectedHash $phaseFiveActualHash -SimulatedProcessNames @() -OutputPath $missingParent -ExpectThrow
    }
    catch {
        $absentParentError = $_
    }
    'Scenario output-path-absent-parent: error=' + ($null -ne $absentParentError)
    Assert-True -Condition ($null -ne $absentParentError) -Message 'OutputPath scenario did not throw when the parent directory was absent.'
    Assert-True -Condition ($absentParentError.Exception.Message -match 'parent directory') -Message "OutputPath absent-parent error did not mention parent directory. Got: $($absentParentError.Exception.Message)"
    Assert-True -Condition (-not (Test-Path -LiteralPath $missingParent -PathType Leaf)) -Message 'OutputPath scenario created a file even though the parent did not exist.'

    'Global apply readiness regression: PASS'
    exit 0
}
finally {
    if (Test-Path -LiteralPath $tempParent) {
        Remove-Item -LiteralPath $tempParent -Recurse -Force -ErrorAction SilentlyContinue
    }
}
