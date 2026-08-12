[CmdletBinding()]
param(
    [string]$Root,
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe',
    [string]$PluginTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim.json',
    [string]$OrchestratorPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md',
    [string]$FixerPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\fixer.md',
    [string]$OraclePromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\oracle.md',
    [string]$DebuggingSkillTarget = 'C:\Users\quang\.config\opencode\skills\systematic-debugging\SKILL.md',
    [string]$VerificationSkillTarget = 'C:\Users\quang\.config\opencode\skills\verification-before-completion\SKILL.md'
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}
if (-not (Test-Path -LiteralPath $Managed -PathType Leaf)) {
    throw "Managed OpenCode binary not found: $Managed"
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-ManagedOpenCode {
    param([string[]]$Arguments)
    $output = & $Managed @Arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Managed OpenCode command failed: $Managed $($Arguments -join ' ')`n$output"
    }
    return $output
}

$pairs = @(
    [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'); Target = $OrchestratorPromptTarget },
    [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\fixer.md'); Target = $FixerPromptTarget },
    [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\oracle.md'); Target = $OraclePromptTarget },
    [pscustomobject]@{ Source = (Join-Path $Root 'skills\systematic-debugging\SKILL.md'); Target = $DebuggingSkillTarget },
    [pscustomobject]@{ Source = (Join-Path $Root 'skills\verification-before-completion\SKILL.md'); Target = $VerificationSkillTarget }
)
foreach ($pair in $pairs) {
    Assert-True -Condition (Test-Path -LiteralPath $pair.Target -PathType Leaf) -Message "Active Phase 7 target is missing: $($pair.Target)"
    Assert-True -Condition ((Get-FileHash -LiteralPath $pair.Source -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $pair.Target -Algorithm SHA256).Hash) -Message "Active Phase 7 target differs from reviewed source: $($pair.Target)"
}

$pluginConfig = Get-Content -LiteralPath $PluginTarget -Raw | ConvertFrom-Json -ErrorAction Stop
foreach ($skill in @('systematic-debugging', 'verification-before-completion')) {
    Assert-True -Condition ($pluginConfig.presets.'sdd-personal'.fixer.skills -contains $skill) -Message "Active slim source does not grant $skill to Fixer."
}

$logs = Invoke-ManagedOpenCode -Arguments @('debug', 'config', '--print-logs')
Assert-True -Condition ($logs -notmatch 'failed to load plugin|INIT FAILED|disabledTools\.filter') -Message 'Slim did not initialize successfully; inspect managed OpenCode plugin logs.'
$configText = Invoke-ManagedOpenCode -Arguments @('debug', 'config')
$config = $configText | ConvertFrom-Json -ErrorAction Stop
Assert-True -Condition ($config.agent.orchestrator.prompt.Contains('Task Brief')) -Message 'Managed Orchestrator prompt is missing the Phase 7 task-brief contract.'
Assert-True -Condition ($config.agent.fixer.prompt.Contains('Task Brief Contract')) -Message 'Managed Fixer prompt is missing the Phase 7 worker contract.'
Assert-True -Condition ($config.agent.oracle.prompt.Contains('two failed repair attempts')) -Message 'Managed Oracle prompt is missing the Phase 7 escalation contract.'

$agents = Invoke-ManagedOpenCode -Arguments @('agent', 'list')
foreach ($agent in @('fixer', 'oracle')) {
    Assert-True -Condition ($agents -match "(?m)^$agent \(") -Message "Managed $agent agent is not registered."
}

'Phase 7 execution and verification runtime: PASS'
