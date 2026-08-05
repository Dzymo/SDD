[CmdletBinding()]
param(
    [string]$Root,
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe',
    [string]$PluginTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim.json',
    [string]$DesignerPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\designer.md',
    [string]$ObserverPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\observer.md',
    [string]$SkillTarget = 'C:\Users\quang\.config\opencode\skills\ui-quality\SKILL.md'
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
    [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\designer.md'); Target = $DesignerPromptTarget },
    [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\observer.md'); Target = $ObserverPromptTarget },
    [pscustomobject]@{ Source = (Join-Path $Root 'skills\ui-quality\SKILL.md'); Target = $SkillTarget }
)
foreach ($item in $sourcesAndTargets) {
    Assert-True -Condition (Test-Path -LiteralPath $item.Target -PathType Leaf) -Message "Active Phase 9 target is missing: $($item.Target)"
    $sourceHash = (Get-FileHash -LiteralPath $item.Source -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $item.Target -Algorithm SHA256).Hash
    Assert-True -Condition ($sourceHash -eq $targetHash) -Message "Active Phase 9 target differs from reviewed source: $($item.Target)"
}

$pluginConfig = Get-Content -LiteralPath $PluginTarget -Raw | ConvertFrom-Json -ErrorAction Stop
Assert-True -Condition ($pluginConfig.presets.'sdd-personal'.designer.skills -contains 'ui-quality') -Message 'Active slim source does not grant ui-quality to Designer.'

$logs = Invoke-ManagedOpenCode -Arguments @('debug', 'config', '--print-logs')
Assert-True -Condition ($logs -notmatch 'failed to load plugin|INIT FAILED|disabledTools\.filter') -Message 'Slim did not initialize successfully; inspect managed OpenCode plugin logs.'

$configText = Invoke-ManagedOpenCode -Arguments @('debug', 'config')
try {
    $config = $configText | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Managed OpenCode did not return valid effective JSON. $($_.Exception.Message)"
}

Assert-True -Condition ($config.agent.designer.prompt.Contains('Authority Order')) -Message 'Managed Designer prompt is missing the Phase 9 authority contract.'
Assert-True -Condition ($config.agent.designer.prompt.Contains('synthetic quality scores')) -Message 'Managed Designer prompt is missing the Phase 9 synthetic-score prohibition.'
Assert-True -Condition ($config.agent.observer.prompt.Contains('Independent UI Review')) -Message 'Managed Observer prompt is missing the Phase 9 screenshot-review contract.'
Assert-True -Condition ($config.agent.designer.permission.skill.'ui-quality' -eq 'allow') -Message 'Managed Designer does not have permission to load the ui-quality skill.'

$agents = Invoke-ManagedOpenCode -Arguments @('agent', 'list')
Assert-True -Condition ($agents -match '(?m)^designer \(') -Message 'Managed Designer agent is not registered.'
$designerBlock = [regex]::Match($agents, '(?ms)^designer \(.*?(?=^[a-z-]+ \(|\z)')
Assert-True -Condition $designerBlock.Success -Message 'Could not inspect the managed Designer agent.'
Assert-True -Condition ($designerBlock.Value -match '"permission": "skill",\s*"pattern": "ui-quality",\s*"action": "allow"') -Message 'Managed Designer agent list does not expose ui-quality skill permission.'

'Phase 9 UI quality layer runtime: PASS'
