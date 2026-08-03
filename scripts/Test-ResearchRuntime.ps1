[CmdletBinding()]
param(
    [string]$Root,
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe',
    [string]$Workspace,
    [string]$CodeGraphWorkspace = 'D:\Projects\Docs\codegraph'
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}
if ([string]::IsNullOrWhiteSpace($Workspace)) {
    $Workspace = $Root
}
if (-not (Test-Path -LiteralPath $Managed)) {
    throw "Managed OpenCode binary not found: $Managed"
}
if (-not (Test-Path -LiteralPath $Workspace)) {
    throw "Research workspace not found: $Workspace"
}
if (-not (Test-Path -LiteralPath $CodeGraphWorkspace)) {
    throw "CodeGraph research workspace not found: $CodeGraphWorkspace"
}

function Invoke-ManagedOpenCode {
    param(
        [string[]]$Arguments,
        [string]$AdditionalConfig
    )

    $previousConfig = $env:OPENCODE_CONFIG
    try {
        if ($AdditionalConfig) {
            $env:OPENCODE_CONFIG = $AdditionalConfig
        }
        $output = & $Managed @Arguments 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "Managed OpenCode command failed: $($Arguments -join ' ')"
        }
        return $output
    }
    finally {
        $env:OPENCODE_CONFIG = $previousConfig
    }
}

function Assert-Match {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
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

$configText = Invoke-ManagedOpenCode -Arguments @('debug', 'config')
try {
    $config = $configText | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Managed OpenCode did not return valid effective JSON. $($_.Exception.Message)"
}

Assert-True -Condition ($config.mcp.context7.type -eq 'remote') -Message 'Context7 is not a remote MCP in the managed runtime.'
Assert-True -Condition ($config.mcp.context7.url -eq 'https://mcp.context7.com/mcp/oauth') -Message 'Context7 is not using the approved OAuth endpoint.'
Assert-True -Condition ($config.mcp.context7.enabled -eq $true) -Message 'Context7 is not enabled in the managed runtime.'
Assert-True -Condition ($config.mcp.codegraph.type -eq 'local') -Message 'CodeGraph is not a local MCP in the managed runtime.'
Assert-True -Condition (($config.mcp.codegraph.command -join ' ') -eq 'codegraph serve --mcp') -Message 'CodeGraph does not use the approved command.'
Assert-True -Condition ($config.mcp.codegraph.enabled -eq $true) -Message 'CodeGraph is not enabled in the managed runtime.'
Assert-True -Condition ($config.references.codegraph.path -eq $CodeGraphWorkspace) -Message 'The managed runtime is missing the reviewed CodeGraph reference.'
Assert-True -Condition ($config.references.codegraph.hidden -eq $true) -Message 'The CodeGraph reference must remain hidden.'
Assert-True -Condition ($null -eq $config.mcp.context7.headers) -Message 'Context7 headers are not permitted.'
Assert-True -Condition ($null -eq $config.mcp.codegraph.environment) -Message 'CodeGraph environment values are not permitted.'

$mcpList = Invoke-ManagedOpenCode -Arguments @('mcp', 'list')
Assert-Match -Text $mcpList -Pattern '(?i)context7' -Message 'Context7 is absent from the managed MCP list.'
Assert-Match -Text $mcpList -Pattern '(?i)codegraph' -Message 'CodeGraph is absent from the managed MCP list.'

$authList = Invoke-ManagedOpenCode -Arguments @('mcp', 'auth', 'list')
Assert-Match -Text $authList -Pattern '(?i)context7.*(authenticated|authorized|connected)' -Message 'Context7 OAuth is not authenticated in the managed runtime.'

$codegraph = Get-Command codegraph -ErrorAction SilentlyContinue
if ($null -eq $codegraph) {
    throw 'CodeGraph is not available on PATH.'
}
Push-Location -LiteralPath $CodeGraphWorkspace
try {
    $status = & $codegraph.Source status 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw 'CodeGraph does not report a healthy index for the research workspace.'
    }
}
finally {
    Pop-Location
}

$context7Run = Invoke-ManagedOpenCode -Arguments @(
    'run', '--dir', $Workspace, '--agent', 'orchestrator', '--format', 'json',
    'You MUST call task exactly once with subagent_type librarian. In that child prompt, require it to use Context7 to resolve Zod and query z.object. Return the library ID, selected version, and one cited fact. Do not answer from memory.'
)
Assert-Match -Text $context7Run -Pattern '(?i)context7' -Message 'The Librarian did not invoke Context7.'
Assert-Match -Text $context7Run -Pattern '/colinhacks/zod' -Message 'The Context7 query did not return a resolved Zod library ID.'
Assert-Match -Text $context7Run -Pattern 'v4\.0\.1' -Message 'The Context7 query did not return versioned Zod evidence.'

$codegraphRun = Invoke-ManagedOpenCode -Arguments @(
    'run', '--dir', $Workspace, '--agent', 'orchestrator', '--format', 'json',
    "You MUST call task exactly once with subagent_type explorer. In that child prompt, require it to use CodeGraph with projectPath '$CodeGraphWorkspace' to locate the MCPServer symbol. Return its exact local path and line range. Do not infer the answer from memory."
)
Assert-Match -Text $codegraphRun -Pattern '(?i)codegraph' -Message 'The Explorer did not invoke CodeGraph.'
Assert-Match -Text $codegraphRun -Pattern 'src\\+mcp\\+index\.ts' -Message 'CodeGraph did not return the requested local path evidence.'

$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "phase-3-fallback-$PID"
New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
try {
    $context7Disabled = Join-Path $temporaryDirectory 'context7-disabled.json'
    '{"mcp":{"context7":{"enabled":false}}}' | Set-Content -LiteralPath $context7Disabled -Encoding ascii
    $context7FallbackConfig = Invoke-ManagedOpenCode -AdditionalConfig $context7Disabled -Arguments @('debug', 'config') | ConvertFrom-Json
    Assert-True -Condition ($context7FallbackConfig.mcp.context7.enabled -eq $false) -Message 'The Context7 failure fixture did not disable Context7.'
    Assert-Match -Text $context7FallbackConfig.agent.librarian.prompt -Pattern 'verified external evidence is unavailable' -Message 'The Librarian does not report unavailable verified evidence when fallback retrieval is unavailable.'

    $codegraphDisabled = Join-Path $temporaryDirectory 'codegraph-disabled.json'
    '{"mcp":{"codegraph":{"enabled":false}}}' | Set-Content -LiteralPath $codegraphDisabled -Encoding ascii
    $codegraphFallbackConfig = Invoke-ManagedOpenCode -AdditionalConfig $codegraphDisabled -Arguments @('debug', 'config') | ConvertFrom-Json
    Assert-True -Condition ($codegraphFallbackConfig.mcp.codegraph.enabled -eq $false) -Message 'The CodeGraph failure fixture did not disable CodeGraph.'
    Assert-Match -Text $codegraphFallbackConfig.agent.explorer.prompt -Pattern 'local evidence is unavailable' -Message 'The Explorer does not report unavailable local evidence when inspection tools are absent.'
    Assert-Match -Text $codegraphFallbackConfig.agent.explorer.prompt -Pattern 'never infer missing paths or lines' -Message 'The Explorer does not prohibit inferred CodeGraph fallback evidence.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

'Phase 3 research runtime: PASS'
