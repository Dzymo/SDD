[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$requiredPaths = @(
    'PACKAGE.md',
    'PLAN.md',
    'PHASE-2-FRAMEWORK-SKELETON.md',
    'PHASE-3-RESEARCH-LAYER.md',
    'PHASE-4-AGENT-LAYER.md',
    'PHASE-5-MULTIMEDIA.md',
    'PHASE-6-OPENSPEC-PROJECT-TEMPLATE.md',
    'PHASE-7-EXECUTION-AND-VERIFICATION.md',
    'PHASE-8-OPENCHAMBER-OPERATING-GUIDE.md',
    'PHASE-9-UI-QUALITY-LAYER.md',
    'PHASE-10-PACKAGING-AND-RELEASE.md',
    'PHASE-11-EVALUATION-AND-FAILURE-DRILLS.md',
    'PHASE-12-GLOBAL-ROLLOUT.md',
    'README.md',
    'CHANGELOG.md',
    'HUONG-DAN-SU-DUNG.md',
    'docs\architecture.md',
    'docs\agent-layer.md',
    'docs\openchamber-operating-guide.md',
    'docs\ui-quality-layer.md',
    'docs\packaging-and-release.md',
    'docs\evaluation-and-failure-drills.md',
    'docs\decisions.md',
    'docs\operations.md',
    'docs\model-evals.md',
    'docs\rollback.md',
    'config\opencode\.gitkeep',
    'config\opencode\agent-layer.plugin.json',
    'config\opencode\research-mcp.json',
    'config\opencode\research-references.json',
    'config\opencode\research-mcp.schema.json',
    'config\oh-my-opencode-slim\.gitkeep',
    'config\oh-my-opencode-slim\sdd-personal.json',
    'prompts\.gitkeep',
    'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md',
    'prompts\oh-my-opencode-slim\sdd-personal\explorer.md',
    'prompts\oh-my-opencode-slim\sdd-personal\librarian.md',
    'prompts\oh-my-opencode-slim\sdd-personal\observer.md',
    'prompts\oh-my-opencode-slim\sdd-personal\fixer.md',
    'prompts\oh-my-opencode-slim\sdd-personal\oracle.md',
    'prompts\oh-my-opencode-slim\sdd-personal\designer.md',
    'patches\oh-my-opencode-slim-2.2.8-disabled-tools.patch',
    'patches\oh-my-opencode-slim-2.2.8-observer-attachment.patch',
    'skills\.gitkeep',
    'skills\source-first-research\SKILL.md',
    'skills\systematic-debugging\SKILL.md',
    'skills\verification-before-completion\SKILL.md',
    'skills\ui-quality\SKILL.md',
    'skills\package-and-release\SKILL.md',
    'commands\.gitkeep',
    'templates\project\README.md',
    'templates\project\Test-OpenSpecBootstrapPreflight.ps1',
    'templates\project\PRODUCT.md',
    'templates\project\DESIGN.md',
    'templates\project\PACKAGE.md',
    'templates\project\docs\surfaces\README.md',
    'templates\project\openspec\config.yaml',
    'templates\project\.opencode\commands\opsx-apply.md',
    'templates\project\.opencode\commands\opsx-archive.md',
    'templates\project\.opencode\commands\opsx-explore.md',
    'templates\project\.opencode\commands\opsx-propose.md',
    'templates\project\.opencode\commands\opsx-sync.md',
    'templates\openspec\README.md',
    'templates\openspec\proposal.md',
    'templates\openspec\spec.md',
    'templates\openspec\design.md',
    'templates\openspec\tasks.md',
    'templates\openspec\research.md',
    'templates\openspec\verification.md',
    'templates\openspec\release.md',
    'evals',
    'fixtures\README.md',
    'fixtures\phase-3\research-mcp.valid.json',
    'fixtures\phase-3\research-mcp.invalid-auth.json',
    'fixtures\phase-3\research-mcp.invalid-command.json',
    'fixtures\phase-3\research-mcp.invalid-url.json',
    'fixtures\phase-6\valid-project\openspec\config.yaml',
    'fixtures\phase-6\valid-project\openspec\changes\add-status-endpoint\.openspec.yaml',
    'fixtures\phase-6\valid-project\openspec\changes\add-status-endpoint\proposal.md',
    'fixtures\phase-6\valid-project\openspec\changes\add-status-endpoint\design.md',
    'fixtures\phase-6\valid-project\openspec\changes\add-status-endpoint\tasks.md',
    'fixtures\phase-6\valid-project\openspec\changes\add-status-endpoint\specs\status-endpoint\spec.md',
    'fixtures\phase-6\ci-windows-only\linux-runner\linux-runner.yml',
    'fixtures\phase-6\ci-windows-only\missing-runs-on\missing-runs-on.yml',
    'fixtures\phase-6\ci-windows-only\matrix-runner\matrix-runner.yml',
    'fixtures\phase-6\ci-windows-only\matrix-include\matrix-include.yml',
    'fixtures\phase-6\ci-windows-only\matrix-include-windows-only\matrix-include-windows-only.yml',
    'fixtures\phase-6\ci-windows-only\reusable-job\reusable-job.yml',
    'fixtures\phase-6\ci-windows-only\valid-windows\valid-windows.yml',
    'fixtures\phase-6\ci-windows-only\multi-windows\multi-windows.yml',
    'fixtures\phase-6\ci-windows-only\matrix-windows-only\matrix-windows-only.yml',
    'fixtures\phase-7\feature\record.json',
    'fixtures\phase-7\bug\record.json',
    'fixtures\phase-7\failed-command-false-pass.json',
    'fixtures\phase-7\two-failed-repairs.json',
    'fixtures\phase-7\missing-task-id.json',
    'fixtures\phase-7\invalid-task-id.json',
    'fixtures\phase-7\empty-command.json',
    'fixtures\phase-7\empty-output.json',
    'fixtures\phase-7\no-attempts.json',
    'fixtures\phase-7\missing-regression-evidence.json',
    'fixtures\phase-8\advisory-scenarios.json',
    'fixtures\phase-9\ui-review-scenarios.json',
    'fixtures\phase-10\release-scenarios.json',
    'fixtures\phase-10\clean-package\package.json',
    'fixtures\phase-10\clean-package\index.js',
    'fixtures\phase-11\failure-drills.json',
    'release-candidates\v0.1.0-rc.1.json',
    'release-candidates\v0.1.0.json',
    'scripts\Test-FrameworkSkeleton.ps1',
    'scripts\Test-ResearchConfigSchema.ps1',
    'scripts\Apply-ResearchMcp.ps1',
    'scripts\Test-ResearchRuntime.ps1',
    'scripts\Test-AgentLayer.ps1',
    'scripts\Test-AgentLayerRuntime.ps1',
    'scripts\Test-MultimediaCapabilities.ps1',
    'scripts\Test-ObserverAttachment.ps1',
    'scripts\Test-ObserverAttachmentRegression.ps1',
    'scripts\Test-ObserverAttachmentPreflight.ps1',
    'scripts\Test-OpenSpecProjectTemplate.ps1',
    'scripts\Test-OpenSpecLifecycle.ps1',
    'scripts\Test-ReleaseCandidate.ps1',
    'scripts\Test-ReleaseCandidateAssets.ps1',
    'scripts\New-ReleaseCandidatePackage.ps1',
    'scripts\CiWindowsOnly.psm1',
    'scripts\Test-CiWindowsOnlyRegression.ps1',
    'scripts\Test-ExecutionVerification.ps1',
    'scripts\Apply-ExecutionVerification.ps1',
    'scripts\Test-ExecutionVerificationApply.ps1',
    'scripts\Test-ExecutionVerificationRuntime.ps1',
    'scripts\Test-ManagedRuntimeIsolated.ps1',
    'scripts\Apply-OpenChamberOperatingGuide.ps1',
    'scripts\Test-OpenChamberOperatingGuide.ps1',
    'scripts\Test-OpenChamberOperatingGuideRuntime.ps1',
    'scripts\Test-UIQualityLayer.ps1',
    'scripts\Apply-UIQualityLayer.ps1',
    'scripts\Test-UIQualityLayerRuntime.ps1',
    'scripts\Test-PackagingRelease.ps1',
    'scripts\Apply-PackagingRelease.ps1',
    'scripts\Test-PackagingReleaseRuntime.ps1',
    'scripts\Test-EvaluationFailureDrills.ps1',
    'scripts\Invoke-Phase12RollbackDrill.ps1',
    'scripts\Test-Phase12RollbackDrill.ps1',
    'scripts\Test-GlobalApplyReadiness.ps1',
    'scripts\Test-GlobalApplyReadinessRegression.ps1',
    '.github\workflows\research-config.yml'
)

$failures = @()
foreach ($relativePath in $requiredPaths) {
    $path = Join-Path $Root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $failures += "Missing required path: $relativePath"
    }
}

$templateCommands = Join-Path $Root 'templates\project\.opencode\commands'
$expectedOpenSpecCommands = @(
    'opsx-apply.md',
    'opsx-archive.md',
    'opsx-explore.md',
    'opsx-propose.md',
    'opsx-sync.md'
)
if (Test-Path -LiteralPath $templateCommands -PathType Container) {
    $actualCommandNames = @(Get-ChildItem -LiteralPath $templateCommands -File |
        ForEach-Object { $_.Name })
    $unexpectedCommands = @($actualCommandNames | Where-Object { $_ -notin $expectedOpenSpecCommands })
    $missingCommands = @($expectedOpenSpecCommands | Where-Object { $_ -notin $actualCommandNames })
    foreach ($command in $unexpectedCommands) {
        $failures += "Unexpected project template command: $command"
    }
    foreach ($command in $missingCommands) {
        $failures += "Missing OpenSpec project template command: $command"
    }
}

$workflowPath = Join-Path $Root '.github\workflows\research-config.yml'
if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
    if ($workflowContent -notmatch '(?ms)^\s*push:\s*\r?\n\s*branches:\s*\r?\n\s*-\s*main\s*$') {
        $failures += 'CI workflow must run automatically on pushes to main.'
    }
    if ($workflowContent -notmatch '(?ms)uses:\s*actions/checkout@[^\r\n]+\r?\n\s*with:\s*\r?\n\s*fetch-depth:\s*0\s*$') {
        $failures += 'CI workflow must fetch full history for immutable release-target packaging.'
    }
    if ($workflowContent -notmatch '@fission-ai/openspec@1\.5\.0') {
        $failures += 'OpenSpec bootstrap CI check must install @fission-ai/openspec@1.5.0.'
    }
    if ($workflowContent -notmatch 'Test-OpenSpecBootstrapPreflight\.ps1') {
        $failures += 'OpenSpec bootstrap CI check must run the copied preflight script.'
    }
    if ($workflowContent -notmatch 'Test-CiWindowsOnlyRegression\.ps1') {
        $failures += 'CI workflow must run the Windows-only runner fixture regression.'
    }
    if ($workflowContent -notmatch 'Test-ExecutionVerification\.ps1') {
        $failures += 'CI workflow must run the Phase 7 execution and verification fixture gate.'
    }
    if ($workflowContent -notmatch 'Test-ExecutionVerificationApply\.ps1') {
        $failures += 'CI workflow must run the isolated Phase 7 apply regression gate.'
    }
    if ($workflowContent -notmatch 'Test-ManagedRuntimeIsolated\.ps1') {
        $failures += 'CI workflow must run the isolated managed-runtime smoke.'
    }
    if ($workflowContent -notmatch 'Test-OpenChamberOperatingGuide\.ps1') {
        $failures += 'CI workflow must run the Phase 8 OpenChamber operating-guide fixture gate.'
    }
    if ($workflowContent -notmatch 'Test-UIQualityLayer\.ps1') {
        $failures += 'CI workflow must run the Phase 9 UI-quality fixture gate.'
    }
    if ($workflowContent -notmatch 'Test-PackagingRelease\.ps1') {
        $failures += 'CI workflow must run the Phase 10 packaging and release fixture gate.'
    }
    if ($workflowContent -notmatch 'Test-EvaluationFailureDrills\.ps1') {
        $failures += 'CI workflow must run the Phase 11 evaluation and failure-drill gate.'
    }
    if ($workflowContent -notmatch 'Test-Phase12RollbackDrill\.ps1') {
        $failures += 'CI workflow must run the Phase 12 rollback drill regression gate.'
    }
    if ($workflowContent -notmatch 'Test-GlobalApplyReadinessRegression\.ps1') {
        $failures += 'CI workflow must run the global apply readiness preflight regression gate.'
    }
    if ($workflowContent -notmatch 'Test-OpenSpecProjectTemplate\.ps1') {
        $failures += 'CI workflow must run the strict OpenSpec project template fixture validator.'
    }
    if ($workflowContent -notmatch 'Test-OpenSpecLifecycle\.ps1') {
        $failures += 'CI workflow must run the isolated OpenSpec lifecycle behavioral gate.'
    }

}

$releaseWorkflowPath = Join-Path $Root '.github\workflows\release-candidate.yml'
if (-not (Test-Path -LiteralPath $releaseWorkflowPath -PathType Leaf)) {
    $failures += 'Release workflow is missing.'
}
else {
    $releaseWorkflowContent = Get-Content -LiteralPath $releaseWorkflowPath -Raw
    foreach ($requiredMarker in @('workflow_dispatch:', 'contents: write', 'New-ReleaseCandidatePackage.ps1', 'Test-ReleaseCandidateAssets.ps1', "'release', 'create'", '$plan.prerelease', '$releaseArguments += ''--prerelease''', '--cleanup-tag')) {
        if (-not $releaseWorkflowContent.Contains($requiredMarker)) {
            $failures += "Release workflow is missing required marker: $requiredMarker"
        }
    }
}

$workflowDirectory = Join-Path $Root '.github\workflows'
try {
    Import-Module (Join-Path $PSScriptRoot 'CiWindowsOnly.psm1') -Force -ErrorAction Stop
    $failures += @(Get-CiWindowsOnlyFailures -WorkflowDirectory $workflowDirectory)
}
catch {
    $failures += "Failed to evaluate Windows-only CI jobs: $($_.Exception.Message)"
}

# Phase 4 permits reviewed, non-secret sources only. They are never provider
# configuration, authentication, OpenChamber state, or deployable backups.
$approvedConfigSources = @(
    (Join-Path $Root 'config\opencode\agent-layer.plugin.json'),
    (Join-Path $Root 'config\opencode\research-mcp.json'),
    (Join-Path $Root 'config\opencode\research-references.json'),
    (Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'),
    (Join-Path $Root 'config\opencode\research-mcp.schema.json')
)
$configFiles = @(Get-ChildItem -LiteralPath (Join-Path $Root 'config') -File -Recurse -Force |
    Where-Object { $_.Name -ne '.gitkeep' })
foreach ($configFile in $configFiles) {
    if ($approvedConfigSources -notcontains $configFile.FullName) {
        $failures += "Unexpected config source: $($configFile.FullName)"
    }
}

$forbiddenName = '(?i)(^|[._-])(secret|token|credential|password|apikey|api-key|private-key)([._-]|$)|(^|\\.)env($|\\.)'
$sensitiveFiles = @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
    Where-Object { $_.FullName -notmatch '\\\.git\\|\\\.slim\\clonedeps\\repos\\|\\\.opencode\\node_modules\\' -and $_.Name -match $forbiddenName })
foreach ($file in $sensitiveFiles) {
    $failures += "Sensitive-looking file is not allowed in the framework source: $($file.FullName)"
}

function Test-IsBinaryTextLikeFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $true
    }

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $textLikeExtensions = @('.md', '.markdown', '.txt', '.ps1', '.psm1', '.psd1', '.json', '.jsonc', '.yaml', '.yml', '.patch', '.diff', '.js', '.cjs', '.mjs', '.ts', '.tsx', '.jsx', '.css', '.html', '.xml', '.ini', '.sh', '.toml')
    if ($extension -notin $textLikeExtensions) {
        return $true
    }

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    }
    catch {
        return $true
    }

    try {
        $buffer = New-Object byte[] 8192
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        for ($i = 0; $i -lt $bytesRead; $i++) {
            if ($buffer[$i] -eq 0) {
                return $true
            }
        }
        return $false
    }
    finally {
        $stream.Dispose()
    }
}

$secretPattern = '(?i)(-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----|sk-[A-Za-z0-9_-]{20,}|(?:api[_-]?key|access[_-]?token|secret|password)\s*[=:]\s*["'']?[A-Za-z0-9_+\/-]{16,})'
$textFiles = @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
    Where-Object {
        $_.FullName -notmatch '\\\.slim\\clonedeps\\repos\\|\\\.opencode\\node_modules\\' -and
        -not (Test-IsBinaryTextLikeFile -Path $_.FullName)
    })
foreach ($file in $textFiles) {
    if (Select-String -LiteralPath $file.FullName -Pattern $secretPattern -Quiet) {
        $failures += "Potential credential marker found in: $($file.FullName)"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { "FAIL: $_" }
    exit 1
}

'Framework source layout and secret checks: PASS'
