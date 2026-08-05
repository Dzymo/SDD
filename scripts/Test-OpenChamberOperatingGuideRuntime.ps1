[CmdletBinding()]
param(
    [string]$Root,
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe',
    [string]$PromptPath = 'C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md'
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$sourcePath = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'
if (-not (Test-Path -LiteralPath $Managed)) {
    throw "Managed OpenCode binary not found: $Managed"
}
if (-not (Test-Path -LiteralPath $PromptPath)) {
    throw "Active Orchestrator prompt not found: $PromptPath"
}
if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Reviewed Phase 8 source prompt not found: $sourcePath"
}

$config = & $Managed debug config 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "Managed OpenCode config check failed.`n$config"
}
if ($config -notmatch 'oh-my-opencode-slim@2\.2\.8') {
    throw 'The pinned slim plugin is not active in the managed OpenCode configuration.'
}

$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$targetHash = (Get-FileHash -LiteralPath $PromptPath -Algorithm SHA256).Hash
if ($sourceHash -ne $targetHash) {
    throw "Active Orchestrator prompt hash does not match the reviewed Phase 8 source. Source SHA-256: $sourceHash. Target SHA-256: $targetHash."
}

$prompt = Get-Content -LiteralPath $PromptPath -Raw
foreach ($rule in @('OpenChamber recommendation', 'self-contained finish line', 'never arm, resume, change its budget', 'While a Session Goal shows Evaluating', 'Recommend MultiRun only', 'explicit user approval')) {
    if (-not $prompt.Contains($rule)) {
        throw "Active Orchestrator prompt is missing required Phase 8 rule: $rule"
    }
}

'Phase 8 OpenChamber operating guide runtime: PASS'
