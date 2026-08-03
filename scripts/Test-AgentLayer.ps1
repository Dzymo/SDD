[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Assert-Equal {
    param(
        [object]$Actual,
        [object]$Expected,
        [string]$Message
    )

    if ($Actual -cne $Expected) {
        throw "$Message Expected '$Expected'; received '$Actual'."
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Read-JsonSource {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required source not found: $Path"
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Invalid JSON source '$Path'. $($_.Exception.Message)"
    }
}

$pluginSourcePath = Join-Path $Root 'config\opencode\agent-layer.plugin.json'
$presetSourcePath = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$promptRoot = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal'

$pluginSource = Read-JsonSource -Path $pluginSourcePath
Assert-Equal -Actual $pluginSource.'$schema' -Expected 'https://opencode.ai/config.json' -Message 'Plugin source must use the OpenCode schema.'
Assert-True -Condition ($pluginSource.plugin.Count -eq 1) -Message 'Plugin source must register exactly one plugin.'
Assert-Equal -Actual $pluginSource.plugin[0] -Expected 'oh-my-opencode-slim@2.2.8' -Message 'Plugin source must pin the reviewed slim version.'

$preset = Read-JsonSource -Path $presetSourcePath
Assert-Equal -Actual $preset.preset -Expected 'sdd-personal' -Message 'Unexpected active preset.'
Assert-Equal -Actual $preset.setDefaultAgent -Expected $true -Message 'The Orchestrator must become the default agent.'
Assert-Equal -Actual $preset.autoUpdate -Expected $false -Message 'Slim automatic updates must stay disabled.'
Assert-True -Condition ($preset.disabled_agents -contains 'council') -Message 'Council must be disabled.'
Assert-True -Condition (-not ($preset.disabled_agents -contains 'observer')) -Message 'Observer must remain enabled for structured image handoff.'
Assert-Equal -Actual $preset.image_routing -Expected 'auto' -Message 'Image routing must save parent attachments before the Terra request.'
Assert-True -Condition ($preset.disabled_skills -contains 'worktrees') -Message 'Slim worktree skill must be disabled.'
foreach ($mcp in @('websearch', 'context7', 'gh_grep')) {
    Assert-True -Condition ($preset.disabled_mcps -contains $mcp) -Message "Unreviewed plugin MCP '$mcp' must be disabled."
}
Assert-Equal -Actual $preset.multiplexer.type -Expected 'none' -Message 'Multiplexer must be disabled.'
Assert-Equal -Actual $preset.companion.enabled -Expected $false -Message 'Companion must be disabled.'
Assert-Equal -Actual $preset.backgroundJobs.continueOnIdle -Expected $false -Message 'Idle continuation must be disabled.'
Assert-Equal -Actual $preset.backgroundJobs.maxSessionsPerAgent -Expected 1 -Message 'Only one reusable session per specialist is allowed.'
Assert-Equal -Actual $preset.fallback.maxRetries -Expected 1 -Message 'Model fallback retries must remain bounded.'
Assert-True -Condition ($preset.presets.'sdd-personal'.orchestrator.mcps.Count -eq 0) -Message 'The Orchestrator must not receive direct MCP access.'
Assert-True -Condition (($preset.presets.'sdd-personal'.librarian.mcps -join ',') -eq 'context7') -Message 'The Librarian must receive only Context7 MCP access.'
Assert-True -Condition (($preset.presets.'sdd-personal'.explorer.mcps -join ',') -eq 'codegraph') -Message 'The Explorer must receive only CodeGraph MCP access.'

$expectedRoutes = @{
    orchestrator = @('cliproxy/gpt-5.6-terra', 'medium', 'high')
    oracle = @('cliproxy/gpt-5.6-sol', 'medium', 'high')
    librarian = @('minimax-coding-plan/MiniMax-M3', 'none', 'thinking')
    explorer = @('minimax-coding-plan/MiniMax-M3', 'none', 'thinking')
    designer = @('minimax-coding-plan/MiniMax-M3', 'thinking', 'none')
    fixer = @('minimax-coding-plan/MiniMax-M3', 'none', 'thinking')
    observer = @('minimax-coding-plan/MiniMax-M3', 'none', 'thinking')
}

foreach ($role in $expectedRoutes.Keys) {
    $route = $preset.presets.'sdd-personal'.$role.model
    Assert-True -Condition ($route.Count -eq 2) -Message "$role must have a primary route and one fallback."
    Assert-Equal -Actual $route[0].id -Expected $expectedRoutes[$role][0] -Message "$role has an unexpected primary model."
    Assert-Equal -Actual $route[0].variant -Expected $expectedRoutes[$role][1] -Message "$role has an unexpected primary variant."
    Assert-Equal -Actual $route[1].id -Expected $expectedRoutes[$role][0] -Message "$role has an unexpected fallback model."
    Assert-Equal -Actual $route[1].variant -Expected $expectedRoutes[$role][2] -Message "$role has an unexpected fallback variant."
}

$readOnlyRoles = @('explorer', 'librarian', 'oracle', 'observer')
foreach ($role in $readOnlyRoles) {
    $permission = $preset.agents.$role.permission
    foreach ($tool in @('*', 'edit', 'bash', 'task', 'external_directory', 'question')) {
        Assert-Equal -Actual $permission.$tool -Expected 'deny' -Message "$role must deny $tool."
    }
    foreach ($tool in @('read', 'glob', 'grep', 'list')) {
        Assert-Equal -Actual $permission.$tool -Expected 'allow' -Message "$role must allow $tool."
    }
}

Assert-Equal -Actual $preset.agents.librarian.permission.webfetch -Expected 'allow' -Message 'Librarian must be able to retrieve web documentation.'
Assert-Equal -Actual $preset.agents.librarian.permission.websearch -Expected 'allow' -Message 'Librarian must be able to search documentation.'

$requiredPromptRules = @{
    'orchestrator.md' = @('at most two concurrent subagents', 'OpenChamber Advice', 'Respond in Vietnamese', 'observer_attachment', 'Do not use `task`')
    'explorer.md' = @('one focused search batch', 'Use CodeGraph for healthy indexed structural questions', 'local evidence is unavailable', 'never infer missing paths or lines', 'Do not inventory unrelated files', 'call the shell')
    'librarian.md' = @('Context7 first', 'one fallback retrieval round', 'verified external evidence is unavailable', 'Do not use model memory as evidence')
    'observer.md' = @('structured attachments', 'MUST call `read`', 'never edit files')
}

foreach ($promptFile in $requiredPromptRules.Keys) {
    $path = Join-Path $promptRoot $promptFile
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required prompt source not found: $path"
    }
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($rule in $requiredPromptRules[$promptFile]) {
        Assert-True -Condition $content.Contains($rule) -Message "$promptFile is missing its required rule: $rule"
    }
}

'Phase 4 agent layer source: PASS'
