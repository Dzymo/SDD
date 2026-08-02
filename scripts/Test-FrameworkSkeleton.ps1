[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$requiredPaths = @(
    'PLAN.md',
    'README.md',
    'docs\architecture.md',
    'docs\decisions.md',
    'docs\operations.md',
    'docs\model-evals.md',
    'docs\rollback.md',
    'config\opencode\.gitkeep',
    'config\opencode\research-mcp.schema.json',
    'config\oh-my-opencode-slim\.gitkeep',
    'prompts\.gitkeep',
    'skills\.gitkeep',
    'commands\.gitkeep',
    'templates\project\README.md',
    'templates\openspec\README.md',
    'evals',
    'fixtures\README.md',
    'fixtures\phase-3\research-mcp.valid.json',
    'fixtures\phase-3\research-mcp.invalid-auth.json',
    'fixtures\phase-3\research-mcp.invalid-command.json',
    'fixtures\phase-3\research-mcp.invalid-url.json',
    'scripts\Test-FrameworkSkeleton.ps1',
    'scripts\Test-ResearchConfigSchema.ps1'
)

$failures = @()
foreach ($relativePath in $requiredPaths) {
    $path = Join-Path $Root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $failures += "Missing required path: $relativePath"
    }
}

# Phase 3 permits only the reviewed schema, not deployable configuration.
$approvedConfigSources = @(
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
    Where-Object { $_.FullName -notmatch '\\.git\\' -and $_.Name -match $forbiddenName })
foreach ($file in $sensitiveFiles) {
    $failures += "Sensitive-looking file is not allowed in the framework source: $($file.FullName)"
}

$secretPattern = '(?i)(-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----|sk-[A-Za-z0-9_-]{20,}|(?:api[_-]?key|access[_-]?token|secret|password)\s*[=:]\s*["'']?[A-Za-z0-9_+\/-]{16,})'
$textFiles = @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
    Where-Object { $_.Extension -in @('.md', '.ps1', '.json', '.jsonc', '.yaml', '.yml') })
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
