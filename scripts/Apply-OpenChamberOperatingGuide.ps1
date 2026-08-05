[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root,
    [string]$Target = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md',
    [string]$BackupRoot = 'C:\Users\quang\.local\share\opencode\framework-backups'
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$source = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Reviewed Phase 8 source prompt not found: $source"
}
if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) {
    throw "Framework-owned target prompt not found: $Target"
}
if (-not (Test-Path -LiteralPath $BackupRoot -PathType Container)) {
    throw "Protected backup root not found: $BackupRoot"
}

$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match 'openchamber|cpa|opencode'
})
if ($running.Count -gt 0) {
    $processes = $running | ForEach-Object { "$($_.ProcessName) (PID $($_.Id))" }
    throw "Close OpenChamber and CPA GUI before applying the Phase 8 prompt. Running: $($processes -join ', ')"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDirectory = Join-Path $BackupRoot "phase-8-$timestamp"
$backupPrompt = Join-Path $backupDirectory 'orchestrator.md'
$manifest = Join-Path $backupDirectory 'manifest.json'
$beforeHash = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash

if ($PSCmdlet.ShouldProcess($Target, 'back up and apply the reviewed Phase 8 Orchestrator prompt')) {
    New-Item -ItemType Directory -Path $backupDirectory -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath $Target -Destination $backupPrompt -ErrorAction Stop
    try {
        Copy-Item -LiteralPath $source -Destination $Target -Force -ErrorAction Stop
        $afterHash = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
        if ($afterHash -ne $sourceHash) {
            throw 'Phase 8 prompt hash mismatch after apply.'
        }

        [ordered]@{
            phase = 'phase-8'
            source = $source
            target = $Target
            backup = $backupPrompt
            beforeSha256 = $beforeHash
            sourceSha256 = $sourceHash
            afterSha256 = $afterHash
            appliedAt = (Get-Date).ToString('o')
        } | ConvertTo-Json | Set-Content -LiteralPath $manifest -Encoding utf8 -NoNewline -ErrorAction Stop
    }
    catch {
        $failure = $_
        Copy-Item -LiteralPath $backupPrompt -Destination $Target -Force -ErrorAction Stop
        throw "Phase 8 apply failed and the target was restored. $($failure.Exception.Message)"
    }

    "Phase 8 prompt applied: $Target"
    "Backup manifest: $manifest"
    "Restart OpenChamber and run: PowerShell -ExecutionPolicy Bypass -File $PSScriptRoot\Test-OpenChamberOperatingGuideRuntime.ps1"
}
