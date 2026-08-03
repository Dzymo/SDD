[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$requiredPaths = @(
    'PLAN.md',
    'PHASE-2-FRAMEWORK-SKELETON.md',
    'PHASE-3-RESEARCH-LAYER.md',
    'PHASE-4-AGENT-LAYER.md',
    'PHASE-5-MULTIMEDIA.md',
    'PHASE-6-OPENSPEC-PROJECT-TEMPLATE.md',
    'README.md',
    'docs\architecture.md',
    'docs\agent-layer.md',
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
    'patches\oh-my-opencode-slim-2.2.8-disabled-tools.patch',
    'patches\oh-my-opencode-slim-2.2.8-observer-attachment.patch',
    'skills\.gitkeep',
    'skills\source-first-research\SKILL.md',
    'commands\.gitkeep',
    'templates\project\README.md',
    'templates\project\Test-OpenSpecBootstrapPreflight.ps1',
    'templates\project\PRODUCT.md',
    'templates\project\DESIGN.md',
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
    'scripts\CiWindowsOnly.psm1',
    'scripts\Test-CiWindowsOnlyRegression.ps1',
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
    if ($workflowContent -notmatch '@fission-ai/openspec@1\.5\.0') {
        $failures += 'OpenSpec bootstrap CI check must install @fission-ai/openspec@1.5.0.'
    }
    if ($workflowContent -notmatch 'Test-OpenSpecBootstrapPreflight\.ps1') {
        $failures += 'OpenSpec bootstrap CI check must run the copied preflight script.'
    }
    if ($workflowContent -notmatch 'Test-CiWindowsOnlyRegression\.ps1') {
        $failures += 'CI workflow must run the Windows-only runner fixture regression.'
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
    Where-Object { $_.FullName -notmatch '\\.git\\|\\.slim\\clonedeps\\repos\\|\\.opencode\\' -and $_.Name -match $forbiddenName })
foreach ($file in $sensitiveFiles) {
    $failures += "Sensitive-looking file is not allowed in the framework source: $($file.FullName)"
}

$secretPattern = '(?i)(-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----|sk-[A-Za-z0-9_-]{20,}|(?:api[_-]?key|access[_-]?token|secret|password)\s*[=:]\s*["'']?[A-Za-z0-9_+\/-]{16,})'
$textFiles = @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
    Where-Object { $_.FullName -notmatch '\\.slim\\clonedeps\\repos\\|\\.opencode\\' -and $_.Extension -in @('.md', '.ps1', '.json', '.jsonc', '.yaml', '.yml') })
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
