[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root,
    [string]$PluginTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim.json',
    [string]$OrchestratorPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md',
    [string]$FixerPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\fixer.md',
    [string]$OraclePromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\oracle.md',
    [string]$DebuggingSkillTarget = 'C:\Users\quang\.config\opencode\skills\systematic-debugging\SKILL.md',
    [string]$VerificationSkillTarget = 'C:\Users\quang\.config\opencode\skills\verification-before-completion\SKILL.md',
    [string]$BackupRoot = 'C:\Users\quang\.local\share\opencode\framework-backups'
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Get-FileHashOrAbsent {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 'ABSENT'
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Read-JsonFile {
    param([string]$Path)

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Cannot safely read JSON file '$Path'. $($_.Exception.Message)"
    }
}

function Write-JsonUtf8NoBom {
    param([string]$Path, [object]$Value)

    $json = $Value | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Restore-Target {
    param([object]$Entry)

    if ($Entry.BeforeSha256 -eq 'ABSENT') {
        if (Test-Path -LiteralPath $Entry.Target -PathType Leaf) {
            Remove-Item -LiteralPath $Entry.Target -Force -ErrorAction Stop
        }
        return
    }
    Copy-Item -LiteralPath $Entry.Backup -Destination $Entry.Target -Force -ErrorAction Stop
}

$configSource = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$sources = @(
    [pscustomobject]@{ Name = 'oh-my-opencode-slim.json'; Source = $configSource; Target = $PluginTarget; Merge = 'fixer.skills' },
    [pscustomobject]@{ Name = 'orchestrator.md'; Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'); Target = $OrchestratorPromptTarget },
    [pscustomobject]@{ Name = 'fixer.md'; Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\fixer.md'); Target = $FixerPromptTarget },
    [pscustomobject]@{ Name = 'oracle.md'; Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\oracle.md'); Target = $OraclePromptTarget },
    [pscustomobject]@{ Name = 'systematic-debugging.SKILL.md'; Source = (Join-Path $Root 'skills\systematic-debugging\SKILL.md'); Target = $DebuggingSkillTarget },
    [pscustomobject]@{ Name = 'verification-before-completion.SKILL.md'; Source = (Join-Path $Root 'skills\verification-before-completion\SKILL.md'); Target = $VerificationSkillTarget }
)

foreach ($path in @($PluginTarget, $BackupRoot) + $sources.Source) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 7 source or target is missing: $path"
    }
}

& (Join-Path $Root 'scripts\Test-ExecutionVerification.ps1') -Root $Root
if (-not $?) {
    throw 'Phase 7 source validation failed; no global configuration was changed.'
}
& (Join-Path $Root 'scripts\Test-AgentLayer.ps1') -Root $Root
if (-not $?) {
    throw 'Agent-layer source validation failed; no global configuration was changed.'
}

$sourceConfig = Read-JsonFile -Path $configSource
$targetConfig = Read-JsonFile -Path $PluginTarget
$sourceSkills = @($sourceConfig.presets.'sdd-personal'.fixer.skills)
if ($sourceSkills.Count -eq 0 -or $sourceSkills -notcontains 'systematic-debugging' -or $sourceSkills -notcontains 'verification-before-completion') {
    throw 'Reviewed source does not grant the required Phase 7 skills to Fixer.'
}
if ($null -eq $targetConfig.presets.'sdd-personal'.fixer) {
    throw 'Global slim configuration has no sdd-personal Fixer override to update.'
}

$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match 'openchamber|cpa|opencode'
})
if ($running.Count -gt 0) {
    $processes = $running | ForEach-Object { "$($_.ProcessName) (PID $($_.Id))" }
    throw "Close OpenChamber and CPA GUI before applying the Phase 7 execution layer. Running: $($processes -join ', ')"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDirectory = Join-Path $BackupRoot "phase-7-$timestamp"
if (Test-Path -LiteralPath $backupDirectory) {
    throw "Backup directory already exists: $backupDirectory"
}
if (-not $PSCmdlet.ShouldProcess($PluginTarget, 'back up and apply the reviewed Phase 7 execution and verification assets')) {
    return
}

New-Item -ItemType Directory -Path $backupDirectory -ErrorAction Stop | Out-Null
$manifest = @()
try {
    foreach ($item in $sources) {
        $beforeHash = Get-FileHashOrAbsent -Path $item.Target
        $backup = 'ABSENT'
        if ($beforeHash -ne 'ABSENT') {
            $backup = Join-Path $backupDirectory $item.Name
            Copy-Item -LiteralPath $item.Target -Destination $backup -ErrorAction Stop
        }
        $manifest += [pscustomobject]@{
            Name = $item.Name
            Source = $item.Source
            Target = $item.Target
            Backup = $backup
            BeforeSha256 = $beforeHash
        }
    }

    foreach ($entry in $manifest) {
        $parent = Split-Path -Parent $entry.Target
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
        if ($entry.Merge -eq 'fixer.skills') {
            $targetConfig.presets.'sdd-personal'.fixer | Add-Member -NotePropertyName skills -NotePropertyValue $sourceSkills -Force
            Write-JsonUtf8NoBom -Path $entry.Target -Value $targetConfig
        }
        else {
            Copy-Item -LiteralPath $entry.Source -Destination $entry.Target -Force -ErrorAction Stop
        }
        $entry | Add-Member -NotePropertyName AfterSha256 -NotePropertyValue (Get-FileHashOrAbsent -Path $entry.Target)
        if ($entry.Merge -eq 'fixer.skills') {
            $afterConfig = Read-JsonFile -Path $entry.Target
            if (($afterConfig.presets.'sdd-personal'.fixer.skills -join '|') -ne ($sourceSkills -join '|')) {
                throw 'Phase 7 Fixer skill merge did not match the reviewed source.'
            }
        }
        elseif ($entry.AfterSha256 -ne (Get-FileHashOrAbsent -Path $entry.Source)) {
            throw "Phase 7 target hash mismatch after apply: $($entry.Target)"
        }
    }

    [ordered]@{
        phase = 'phase-7'
        appliedAt = (Get-Date).ToString('o')
        entries = $manifest
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $backupDirectory 'manifest.json') -Encoding utf8 -NoNewline -ErrorAction Stop
}
catch {
    $failure = $_
    for ($index = $manifest.Count - 1; $index -ge 0; $index--) {
        Restore-Target -Entry $manifest[$index]
    }
    throw "Phase 7 apply failed and changed targets were restored. $($failure.Exception.Message)"
}

"Phase 7 execution and verification layer applied. Backup and manifest: $backupDirectory"
"Restart OpenChamber, then run: PowerShell -ExecutionPolicy Bypass -File $PSScriptRoot\Test-ExecutionVerificationRuntime.ps1"
