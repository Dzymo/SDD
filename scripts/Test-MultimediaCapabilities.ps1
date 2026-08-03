[CmdletBinding()]
param(
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe'
)

if (-not (Test-Path -LiteralPath $Managed)) {
    throw "Managed OpenCode binary not found: $Managed"
}

function Invoke-ManagedOpenCode {
    param([string[]]$Arguments)

    $output = & $Managed @Arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Managed OpenCode command failed: $Managed $($Arguments -join ' ')`n$output"
    }
    return $output
}

function Assert-Match {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

$cliproxy = Invoke-ManagedOpenCode -Arguments @('models', 'cliproxy', '--verbose')
foreach ($model in @('gpt-5.6-terra', 'gpt-5.6-sol')) {
    $pattern = '(?s)"id": "' + [regex]::Escape($model) + '".*?"input": \{.*?"image": false.*?"video": false.*?"pdf": false'
    Assert-Match -Text $cliproxy -Pattern $pattern -Message "$model must remain a text-only OpenCode transport route."
}

$minimax = Invoke-ManagedOpenCode -Arguments @('models', 'minimax-coding-plan', '--verbose')
$m3Pattern = '(?s)"id": "MiniMax-M3".*?"attachment": true.*?"input": \{.*?"image": true.*?"video": true.*?"pdf": false'
Assert-Match -Text $minimax -Pattern $m3Pattern -Message 'MiniMax-M3 must expose image and video input, attachment support, and no PDF input.'

$config = Invoke-ManagedOpenCode -Arguments @('debug', 'config')
try {
    $effectiveConfig = $config | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Managed OpenCode did not return valid effective JSON. $($_.Exception.Message)"
}

if ($null -eq $effectiveConfig.agent.PSObject.Properties['observer']) {
    throw 'Observer must be enabled for the reviewed structured attachment handoff.'
}

if ($effectiveConfig.agent.observer.model -ne 'minimax-coding-plan/MiniMax-M3') {
    throw 'Observer must use the reviewed MiniMax-M3 media route.'
}

if ($effectiveConfig.agent.observer.prompt -notmatch 'structured attachments') {
    throw 'Observer must distinguish direct structured attachments from path-only fallback reads.'
}

'Phase 5 multimedia capability gate: PASS'
