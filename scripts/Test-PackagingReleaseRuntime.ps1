[CmdletBinding()]
param(
    [string]$Root,
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe',
    [string]$OrchestratorPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md',
    [string]$SkillTarget = 'C:\Users\quang\.config\opencode\skills\package-and-release\SKILL.md'
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

function Invoke-ManagedOpenCode {
    param([string[]]$Arguments)

    $output = & $Managed @Arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Managed OpenCode command failed: $Managed $($Arguments -join ' ')`n$output"
    }
    return $output
}

if (-not (Test-Path -LiteralPath $Managed -PathType Leaf)) {
    throw "Managed OpenCode binary not found: $Managed"
}

$sourcesAndTargets = @(
    [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'); Target = $OrchestratorPromptTarget },
    [pscustomobject]@{ Source = (Join-Path $Root 'skills\package-and-release\SKILL.md'); Target = $SkillTarget }
)
foreach ($item in $sourcesAndTargets) {
    Assert-True -Condition (Test-Path -LiteralPath $item.Target -PathType Leaf) -Message "Active Phase 10 target is missing: $($item.Target)"
    $sourceHash = (Get-FileHash -LiteralPath $item.Source -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $item.Target -Algorithm SHA256).Hash
    Assert-True -Condition ($sourceHash -eq $targetHash) -Message "Active Phase 10 target differs from reviewed source: $($item.Target)"
}

$logs = Invoke-ManagedOpenCode -Arguments @('debug', 'config', '--print-logs')
Assert-True -Condition ($logs -notmatch 'failed to load plugin|INIT FAILED|disabledTools\.filter') -Message 'Slim did not initialize successfully; inspect managed OpenCode plugin logs.'

$configText = Invoke-ManagedOpenCode -Arguments @('debug', 'config')
try {
    $config = $configText | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Managed OpenCode did not return valid effective JSON. $($_.Exception.Message)"
}
Assert-True -Condition ($config.agent.orchestrator.prompt.Contains('Package And Release')) -Message 'Managed Orchestrator prompt is missing the Phase 10 package and release contract.'
Assert-True -Condition ($config.agent.orchestrator.prompt.Contains('explicit user approval')) -Message 'Managed Orchestrator prompt is missing the Phase 10 release-approval rule.'

$agents = Invoke-ManagedOpenCode -Arguments @('agent', 'list')
Assert-True -Condition ($agents -match '(?m)^orchestrator \(') -Message 'Managed Orchestrator agent is not registered.'

'Phase 10 packaging and release runtime: PASS'
