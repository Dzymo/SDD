[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root,
    [string]$OrchestratorPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md',
    [string]$SkillTarget = 'C:\Users\quang\.config\opencode\skills\package-and-release\SKILL.md',
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

$sources = @(
    [pscustomobject]@{ Name = 'orchestrator.md'; Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'); Target = $OrchestratorPromptTarget },
    [pscustomobject]@{ Name = 'package-and-release.SKILL.md'; Source = (Join-Path $Root 'skills\package-and-release\SKILL.md'); Target = $SkillTarget }
)
foreach ($path in @($BackupRoot) + $sources.Source) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 10 source or target parent is missing: $path"
    }
}

& (Join-Path $Root 'scripts\Test-PackagingRelease.ps1') -Root $Root
if (-not $?) {
    throw 'Phase 10 source validation failed; no global configuration was changed.'
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
    throw "Close OpenChamber and CPA GUI before applying the Phase 10 packaging and release layer. Running: $($processes -join ', ')"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDirectory = Join-Path $BackupRoot "phase-10-$timestamp"
if (Test-Path -LiteralPath $backupDirectory) {
    throw "Backup directory already exists: $backupDirectory"
}
if (-not $PSCmdlet.ShouldProcess($OrchestratorPromptTarget, 'back up and apply the reviewed Phase 10 packaging and release assets')) {
    return
}

New-Item -ItemType Directory -Path $backupDirectory -ErrorAction Stop | Out-Null
$manifest = @()
try {
    foreach ($source in $sources) {
        $beforeHash = Get-FileHashOrAbsent -Path $source.Target
        $backup = 'ABSENT'
        if ($beforeHash -ne 'ABSENT') {
            $backup = Join-Path $backupDirectory $source.Name
            Copy-Item -LiteralPath $source.Target -Destination $backup -ErrorAction Stop
        }
        $manifest += [pscustomobject]@{
            Name = $source.Name
            Source = $source.Source
            Target = $source.Target
            Backup = $backup
            BeforeSha256 = $beforeHash
        }
    }

    foreach ($entry in $manifest) {
        $parent = Split-Path -Parent $entry.Target
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
        Copy-Item -LiteralPath $entry.Source -Destination $entry.Target -Force -ErrorAction Stop
        $entry | Add-Member -NotePropertyName AfterSha256 -NotePropertyValue (Get-FileHashOrAbsent -Path $entry.Target)
        if ($entry.AfterSha256 -ne (Get-FileHashOrAbsent -Path $entry.Source)) {
            throw "Phase 10 target hash mismatch after apply: $($entry.Target)"
        }
    }
    [ordered]@{
        phase = 'phase-10'
        appliedAt = (Get-Date).ToString('o')
        entries = $manifest
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $backupDirectory 'manifest.json') -Encoding utf8 -NoNewline -ErrorAction Stop
}
catch {
    $failure = $_
    for ($index = $manifest.Count - 1; $index -ge 0; $index--) {
        Restore-Target -Entry $manifest[$index]
    }
    throw "Phase 10 apply failed and changed targets were restored. $($failure.Exception.Message)"
}

"Phase 10 packaging and release layer applied. Backup and manifest: $backupDirectory"
"Restart OpenChamber, then run: PowerShell -ExecutionPolicy Bypass -File $PSScriptRoot\Test-PackagingReleaseRuntime.ps1"
