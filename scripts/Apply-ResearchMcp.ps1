[CmdletBinding()]
param(
    [string]$Root,
    [string]$ConfigTarget = 'C:\Users\quang\.config\opencode\opencode.jsonc',
    [string]$PluginTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim.json',
    [string]$ExplorerPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\explorer.md',
    [string]$LibrarianPromptTarget = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\librarian.md',
    [string]$SkillTarget = 'C:\Users\quang\.config\opencode\skills\source-first-research\SKILL.md',
    [string]$BackupRoot = 'C:\Users\quang\.local\share\opencode\framework-backups'
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Get-FileHashOrAbsent {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
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
        throw "Cannot safely merge JSON target '$Path'. $($_.Exception.Message)"
    }
}

$researchSource = Join-Path $Root 'config\opencode\research-mcp.json'
$referenceSource = Join-Path $Root 'config\opencode\research-references.json'
$pluginSource = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$explorerPromptSource = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\explorer.md'
$librarianPromptSource = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\librarian.md'
$skillSource = Join-Path $Root 'skills\source-first-research\SKILL.md'

foreach ($path in @($researchSource, $referenceSource, $pluginSource, $explorerPromptSource, $librarianPromptSource, $skillSource, $ConfigTarget, $PluginTarget)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Phase 3 source or target is missing: $path"
    }
}

& (Join-Path $Root 'scripts\Test-ResearchConfigSchema.ps1') -Root $Root
if (-not $?) {
    throw 'Research MCP source validation failed; no global configuration was changed.'
}

& (Join-Path $Root 'scripts\Test-AgentLayer.ps1') -Root $Root
if (-not $?) {
    throw 'Agent-layer source validation failed; no global configuration was changed.'
}

$codegraph = Get-Command codegraph -ErrorAction SilentlyContinue
if ($null -eq $codegraph) {
    throw 'CodeGraph is not available on PATH; install and verify it before applying the Phase 3 MCP.'
}

$config = Read-JsonFile -Path $ConfigTarget
$research = Read-JsonFile -Path $researchSource
$references = Read-JsonFile -Path $referenceSource
if ($null -eq $config.mcp) {
    $config | Add-Member -NotePropertyName mcp -NotePropertyValue ([pscustomobject]@{})
}
foreach ($property in $research.mcp.PSObject.Properties) {
    $config.mcp | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force
}
if ($null -eq $config.references) {
    $config | Add-Member -NotePropertyName references -NotePropertyValue ([pscustomobject]@{})
}
foreach ($property in $references.references.PSObject.Properties) {
    $config.references | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force
}

$backupParent = Split-Path -Parent $BackupRoot
if (-not (Test-Path -LiteralPath $backupParent)) {
    throw "Backup parent does not exist: $backupParent"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDirectory = Join-Path $BackupRoot "phase-3-$timestamp"
if (Test-Path -LiteralPath $backupDirectory) {
    throw "Backup directory already exists: $backupDirectory"
}
New-Item -ItemType Directory -Path $backupDirectory -ErrorAction Stop | Out-Null

$targets = @(
    [pscustomobject]@{ Source = $null; Target = $ConfigTarget; BackupName = 'opencode.jsonc' },
    [pscustomobject]@{ Source = $pluginSource; Target = $PluginTarget; BackupName = 'oh-my-opencode-slim.json' },
    [pscustomobject]@{ Source = $explorerPromptSource; Target = $ExplorerPromptTarget; BackupName = 'explorer.md' },
    [pscustomobject]@{ Source = $librarianPromptSource; Target = $LibrarianPromptTarget; BackupName = 'librarian.md' },
    [pscustomobject]@{ Source = $skillSource; Target = $SkillTarget; BackupName = 'source-first-research.SKILL.md' }
)

$manifest = @()
foreach ($item in $targets) {
    $beforeHash = Get-FileHashOrAbsent -Path $item.Target
    if ($beforeHash -ne 'ABSENT') {
        Copy-Item -LiteralPath $item.Target -Destination (Join-Path $backupDirectory $item.BackupName) -ErrorAction Stop
    }
    $manifest += [pscustomobject]@{
        Source = $item.Source
        Target = $item.Target
        BeforeSha256 = $beforeHash
        Backup = if ($beforeHash -eq 'ABSENT') { 'ABSENT' } else { (Join-Path $backupDirectory $item.BackupName) }
    }
}

$configParent = Split-Path -Parent $ConfigTarget
if (-not (Test-Path -LiteralPath $configParent)) {
    throw "Configuration target parent does not exist: $configParent"
}
$config | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $ConfigTarget -Encoding ascii

foreach ($item in $targets | Where-Object { $null -ne $_.Source }) {
    $targetParent = Split-Path -Parent $item.Target
    if (-not (Test-Path -LiteralPath $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force -ErrorAction Stop | Out-Null
    }
    Copy-Item -LiteralPath $item.Source -Destination $item.Target -Force -ErrorAction Stop
}

foreach ($entry in $manifest) {
    $entry | Add-Member -NotePropertyName AfterSha256 -NotePropertyValue (Get-FileHashOrAbsent -Path $entry.Target)
}
$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $backupDirectory 'manifest.json') -Encoding ascii

"Phase 3 research MCP applied. Backup and manifest: $backupDirectory"
