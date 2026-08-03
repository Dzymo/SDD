[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
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

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Expected,
        [string]$Message
    )

    Assert-True -Condition $Text.Contains($Expected) -Message $Message
}

function Read-RequiredText {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required regression source not found: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw
}

$presetPath = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$preset = Read-RequiredText -Path $presetPath | ConvertFrom-Json -ErrorAction Stop
Assert-True -Condition (-not ($preset.disabled_agents -contains 'observer')) -Message 'Observer must remain enabled for structured image handoff.'
Assert-True -Condition ($preset.image_routing -eq 'auto') -Message 'Parent image routing must remain in auto mode.'

$promptRoot = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal'
$orchestrator = Read-RequiredText -Path (Join-Path $promptRoot 'orchestrator.md')
Assert-Contains -Text $orchestrator -Expected 'observer_attachment' -Message 'Orchestrator must route saved images through observer_attachment.'
Assert-Contains -Text $orchestrator -Expected 'Do not use `task`' -Message 'Orchestrator must not regress to path-only task handoff.'

$observer = Read-RequiredText -Path (Join-Path $promptRoot 'observer.md')
Assert-Contains -Text $observer -Expected 'structured attachments' -Message 'Observer must accept direct structured attachments.'
Assert-Contains -Text $observer -Expected 'MUST call `read`' -Message 'Observer must retain the path-only fallback rule.'

$smoke = Read-RequiredText -Path (Join-Path $Root 'scripts\Test-ObserverAttachment.ps1')
Assert-Contains -Text $smoke -Expected "@('debug', 'config')" -Message 'The smoke must preflight the managed runtime configuration.'
Assert-Contains -Text $smoke -Expected "@('auth', 'list')" -Message 'The smoke must preflight MiniMax credential availability without reading a token.'
Assert-Contains -Text $smoke -Expected "@('models', 'minimax-coding-plan', '--verbose')" -Message 'The smoke must preflight the active M3 image-attachment route.'
Assert-Contains -Text $smoke -Expected 'Observer OCR preflight: PASS' -Message 'The smoke must report a completed preflight before the model call.'
Assert-Contains -Text $smoke -Expected "DrawString('K7N4-Q2P9'" -Message 'The smoke must generate its unique OCR image code.'
Assert-Contains -Text $smoke -Expected '--file $imagePath' -Message 'The smoke must attach the generated image to OpenCode.'
Assert-Contains -Text $smoke -Expected 'observer_session_id' -Message 'The smoke must require a child Observer session.'
Assert-Contains -Text $smoke -Expected 'K7N4[- ]?Q2P9' -Message 'The smoke must require M3 to return the unique image code.'

$runtimePatch = Read-RequiredText -Path (Join-Path $Root 'patches\oh-my-opencode-slim-2.2.8-observer-attachment.patch')
Assert-Contains -Text $runtimePatch -Expected 'createObserverAttachmentTool' -Message 'The runtime patch record must retain the structured child-session tool.'
Assert-Contains -Text $runtimePatch -Expected 'msg.info.agent === "observer"' -Message 'The runtime patch record must preserve Observer attachments from re-stripping.'

'Observer attachment regression source: PASS'
