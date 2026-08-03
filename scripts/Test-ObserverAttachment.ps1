[CmdletBinding()]
param(
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe',
    [string]$Workspace = (Split-Path -Parent $PSScriptRoot),
    [switch]$PreflightOnly
)

if (-not (Test-Path -LiteralPath $Managed)) {
    throw "Managed OpenCode binary not found: $Managed"
}

if (-not (Test-Path -LiteralPath $Workspace)) {
    throw "Smoke workspace not found: $Workspace"
}

function Invoke-ManagedOpenCode {
    param([string[]]$Arguments)

    $output = & $Managed @Arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Managed OpenCode preflight command failed: $($Arguments -join ' ')"
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

function Test-OcrPreflight {
    $configText = Invoke-ManagedOpenCode -Arguments @('debug', 'config')
    try {
        $config = $configText | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Managed OpenCode did not return valid effective JSON. $($_.Exception.Message)"
    }

    if ($null -eq $config.agent.PSObject.Properties['observer']) {
        throw 'Observer is not enabled in the effective managed runtime.'
    }
    if ($config.agent.observer.model -ne 'minimax-coding-plan/MiniMax-M3') {
        throw 'Observer is not routed to MiniMax-M3 in the effective managed runtime.'
    }
    if ($config.agent.orchestrator.prompt -notmatch 'observer_attachment') {
        throw 'The effective Orchestrator prompt does not route images through observer_attachment.'
    }
    if ($config.agent.observer.prompt -notmatch 'structured attachments') {
        throw 'The effective Observer prompt does not accept structured attachments.'
    }

    $credentials = Invoke-ManagedOpenCode -Arguments @('auth', 'list')
    Assert-Match -Text $credentials -Pattern '(?i)minimax' -Message 'No MiniMax credential is available to the managed OpenCode runtime.'

    $models = Invoke-ManagedOpenCode -Arguments @('models', 'minimax-coding-plan', '--verbose')
    $m3Pattern = '(?s)"id": "MiniMax-M3".*?"status": "active".*?"attachment": true.*?"input": \{.*?"image": true'
    Assert-Match -Text $models -Pattern $m3Pattern -Message 'MiniMax-M3 is not an active image-attachment route.'

    'Observer OCR preflight: PASS'
}

Test-OcrPreflight

if ($PreflightOnly) {
    'Observer OCR preflight only: PASS'
    return
}

$imagePath = Join-Path ([System.IO.Path]::GetTempPath()) "observer-attachment-smoke-$PID.png"
try {
    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::new(1200, 360)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $font = [System.Drawing.Font]::new([System.Drawing.FontFamily]::GenericMonospace, 72, [System.Drawing.FontStyle]::Bold)
    try {
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.DrawString('K7N4-Q2P9', $font, [System.Drawing.Brushes]::Black, 100, 120)
        $bitmap.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $font.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }

    $message = 'An image attachment is present. Use observer_attachment with every saved .opencode/images path. Do not use task or read. Return only the visual code from Observer.'
    $output = & $Managed run --dir $Workspace --file $imagePath --format json --print-logs $message 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Observer attachment smoke command failed.`n$output"
    }

    Assert-Match -Text $output -Pattern 'observer_session_id' -Message 'The Orchestrator did not complete an observer_attachment child session.'
    Assert-Match -Text $output -Pattern 'K7N4[- ]?Q2P9' -Message 'M3 did not return the unique visual code from the structured image attachment.'
    'Observer structured attachment smoke: PASS'
}
finally {
    if (Test-Path -LiteralPath $imagePath) {
        Remove-Item -LiteralPath $imagePath -Force
    }
}
