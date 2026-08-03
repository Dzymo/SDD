[CmdletBinding()]
param(
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe'
)

if (-not (Test-Path -LiteralPath $Managed)) {
    throw "Managed OpenCode binary not found: $Managed"
}

function Invoke-ManagedOpenCode {
    param([string[]]$Arguments)

    $output = & $Managed @Arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Managed OpenCode command failed: $Managed $($Arguments -join ' ')`n$output"
    }
    return $output
}

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

$pluginLoad = Invoke-ManagedOpenCode -Arguments @('debug', 'config', '--print-logs')
if ($pluginLoad -match 'failed to load plugin|INIT FAILED|disabledTools\.filter') {
    throw 'Slim did not initialize successfully. See the managed OpenCode plugin logs.'
}

$config = Invoke-ManagedOpenCode -Arguments @('debug', 'config')
Assert-Contains -Text $config -Pattern 'oh-my-opencode-slim@2\.2\.8' -Message 'The pinned slim plugin is not in the effective OpenCode configuration.'

try {
    $effectiveConfig = $config | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Managed OpenCode did not return valid effective JSON. $($_.Exception.Message)"
}

if ($effectiveConfig.default_agent -ne 'orchestrator') {
    throw 'The effective default agent is not orchestrator.'
}

$expectedPrimaryModels = @{
    orchestrator = 'cliproxy/gpt-5.6-terra'
    oracle = 'cliproxy/gpt-5.6-sol'
    librarian = 'minimax-coding-plan/MiniMax-M3'
    explorer = 'minimax-coding-plan/MiniMax-M3'
    designer = 'minimax-coding-plan/MiniMax-M3'
    fixer = 'minimax-coding-plan/MiniMax-M3'
    observer = 'minimax-coding-plan/MiniMax-M3'
}

foreach ($agent in $expectedPrimaryModels.Keys) {
    if ($effectiveConfig.agent.$agent.model -ne $expectedPrimaryModels[$agent]) {
        throw "$agent has an unexpected effective model."
    }
}

foreach ($mcp in @('websearch', 'gh_grep')) {
    if ($null -ne $effectiveConfig.mcp.PSObject.Properties[$mcp]) {
        throw "Unreviewed plugin MCP '$mcp' is active."
    }
}
if ($effectiveConfig.mcp.context7.type -ne 'remote' -or
    $effectiveConfig.mcp.context7.url -ne 'https://mcp.context7.com/mcp/oauth' -or
    $effectiveConfig.mcp.context7.enabled -ne $true) {
    throw 'The reviewed Context7 OAuth MCP is not active.'
}
if ($effectiveConfig.mcp.codegraph.type -ne 'local' -or
    ($effectiveConfig.mcp.codegraph.command -join ' ') -ne 'codegraph serve --mcp' -or
    $effectiveConfig.mcp.codegraph.enabled -ne $true) {
    throw 'The reviewed CodeGraph MCP is not active.'
}

$agents = Invoke-ManagedOpenCode -Arguments @('agent', 'list')
foreach ($agent in @('orchestrator', 'explorer', 'librarian', 'oracle', 'designer', 'fixer', 'observer')) {
    Assert-Contains -Text $agents -Pattern "(?m)^$agent \(" -Message "Expected agent '$agent' is not registered."
}

foreach ($agent in @('explorer', 'librarian', 'oracle')) {
    $match = [regex]::Match($agents, "(?ms)^$agent \(.*?(?=^[a-z-]+ \(|\z)")
    if (-not $match.Success) {
        throw "Could not inspect permissions for '$agent'."
    }

    foreach ($tool in @('edit', 'bash', 'task', 'external_directory')) {
        $permissionPattern = '"permission": "{0}",\s*"action": "deny"' -f [regex]::Escape($tool)
        Assert-Contains -Text $match.Value -Pattern $permissionPattern -Message "$agent does not deny $tool."
    }
}

'Phase 4 agent layer runtime: PASS'
