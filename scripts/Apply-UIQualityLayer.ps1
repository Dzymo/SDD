[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root,
    [string]$PluginTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim.json',
    [string]$DesignerPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\designer.md',
    [string]$ObserverPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\observer.md',
    [string]$SkillTarget = 'C:\Users\quang\.config\opencode\skills\ui-quality\SKILL.md',
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
$designerPromptSource = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\designer.md'
$observerPromptSource = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\observer.md'
$skillSource = Join-Path $Root 'skills\ui-quality\SKILL.md'

foreach ($path in @($configSource, $designerPromptSource, $observerPromptSource, $skillSource, $PluginTarget, $BackupRoot)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 9 source or target is missing: $path"
    }
}

& (Join-Path $Root 'scripts\Test-UIQualityLayer.ps1') -Root $Root
if (-not $?) {
    throw 'Phase 9 source validation failed; no global configuration was changed.'
}
& (Join-Path $Root 'scripts\Test-AgentLayer.ps1') -Root $Root
if (-not $?) {
    throw 'Agent-layer source validation failed; no global configuration was changed.'
}

$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match 'openchamber|cpa|opencode'
})
if ($running.Count -gt 0) {
    $processes = $running | ForEach-Object { "$($_.ProcessName) (PID $($_.Id))" }
    throw "Close OpenChamber and CPA GUI before applying the Phase 9 UI quality layer. Running: $($processes -join ', ')"
}

$sourceConfig = Read-JsonFile -Path $configSource
$targetConfig = Read-JsonFile -Path $PluginTarget
$sourceSkills = @($sourceConfig.presets.'sdd-personal'.designer.skills)
if ($sourceSkills.Count -eq 0 -or $sourceSkills -notcontains 'ui-quality') {
    throw 'Reviewed source does not grant the ui-quality skill to Designer.'
}
if ($null -eq $targetConfig.presets.'sdd-personal'.designer) {
    throw 'Global slim configuration has no sdd-personal Designer override to update.'
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDirectory = Join-Path $BackupRoot "phase-9-$timestamp"
if (Test-Path -LiteralPath $backupDirectory) {
    throw "Backup directory already exists: $backupDirectory"
}

$targets = @(
    [pscustomobject]@{ Name = 'oh-my-opencode-slim.json'; Source = $configSource; Target = $PluginTarget; BackupName = 'oh-my-opencode-slim.json'; Merge = 'designer.skills' },
    [pscustomobject]@{ Name = 'designer.md'; Source = $designerPromptSource; Target = $DesignerPromptTarget; BackupName = 'designer.md'; Merge = $null },
    [pscustomobject]@{ Name = 'observer.md'; Source = $observerPromptSource; Target = $ObserverPromptTarget; BackupName = 'observer.md'; Merge = $null },
    [pscustomobject]@{ Name = 'ui-quality.SKILL.md'; Source = $skillSource; Target = $SkillTarget; BackupName = 'ui-quality.SKILL.md'; Merge = $null }
)

if (-not $PSCmdlet.ShouldProcess($PluginTarget, 'back up and apply the reviewed Phase 9 UI quality layer')) {
    return
}

New-Item -ItemType Directory -Path $backupDirectory -ErrorAction Stop | Out-Null
$manifest = @()
foreach ($item in $targets) {
    $beforeHash = Get-FileHashOrAbsent -Path $item.Target
    $backup = 'ABSENT'
    if ($beforeHash -ne 'ABSENT') {
        $backup = Join-Path $backupDirectory $item.BackupName
        Copy-Item -LiteralPath $item.Target -Destination $backup -ErrorAction Stop
    }
    $manifest += [pscustomobject]@{
        Name = $item.Name
        Source = $item.Source
        Target = $item.Target
        Merge = $item.Merge
        Backup = $backup
        BeforeSha256 = $beforeHash
    }
}

$writeStarted = $false
try {
    $writeStarted = $true
    $targetConfig.presets.'sdd-personal'.designer | Add-Member -NotePropertyName skills -NotePropertyValue $sourceSkills -Force
    Write-JsonUtf8NoBom -Path $PluginTarget -Value $targetConfig

    foreach ($item in $targets | Where-Object { $null -eq $_.Merge }) {
        $targetParent = Split-Path -Parent $item.Target
        if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
            New-Item -ItemType Directory -Path $targetParent -Force -ErrorAction Stop | Out-Null
        }
        Copy-Item -LiteralPath $item.Source -Destination $item.Target -Force -ErrorAction Stop
    }

    $afterConfig = Read-JsonFile -Path $PluginTarget
    $afterSkills = @($afterConfig.presets.'sdd-personal'.designer.skills)
    if (($afterSkills -join '|') -ne ($sourceSkills -join '|')) {
        throw 'Phase 9 Designer skill merge did not match the reviewed source.'
    }
    foreach ($item in $targets | Where-Object { $null -eq $_.Merge }) {
        $sourceHash = Get-FileHashOrAbsent -Path $item.Source
        $targetHash = Get-FileHashOrAbsent -Path $item.Target
        if ($sourceHash -ne $targetHash) {
            throw "Phase 9 target hash mismatch after apply: $($item.Target)"
        }
    }

    foreach ($entry in $manifest) {
        $entry | Add-Member -NotePropertyName AfterSha256 -NotePropertyValue (Get-FileHashOrAbsent -Path $entry.Target)
    }
    [ordered]@{
        phase = 'phase-9'
        appliedAt = (Get-Date).ToString('o')
        entries = $manifest
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $backupDirectory 'manifest.json') -Encoding utf8 -NoNewline -ErrorAction Stop
}
catch {
    $failure = $_
    if ($writeStarted) {
        for ($index = $manifest.Count - 1; $index -ge 0; $index--) {
            Restore-Target -Entry $manifest[$index]
        }
    }
    throw "Phase 9 apply failed and changed targets were restored. $($failure.Exception.Message)"
}

"Phase 9 UI quality layer applied. Backup and manifest: $backupDirectory"
"Restart OpenChamber, then run: PowerShell -ExecutionPolicy Bypass -File $PSScriptRoot\Test-UIQualityLayerRuntime.ps1"
