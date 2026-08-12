[CmdletBinding()]
param(
    [string]$Managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe',
    [string]$Workspace,
    [string]$PackageRoot = (Join-Path $env:USERPROFILE '.cache\opencode\packages\oh-my-opencode-slim@2.2.8\node_modules\oh-my-opencode-slim'),
    [switch]$PreflightOnly,
    [switch]$SkipRuntimePatchPreflightForMock
)

if ([string]::IsNullOrWhiteSpace($Workspace)) {
    $Workspace = Split-Path -Parent $PSScriptRoot
}

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

function Test-RuntimePatchPresence {
    param(
        [string]$Path,
        [string]$ExpectedAfterHash
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Structured attachment target is missing: $Path"
    }

    $actualHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actualHash -ne $ExpectedAfterHash) {
        throw "Structured attachment hash mismatch for ${Path}: expected $ExpectedAfterHash, found $actualHash."
    }
}

function Test-RuntimePatchPreflight {
    if (-not (Test-Path -LiteralPath $PackageRoot -PathType Container)) {
        throw "Structured attachment package root is missing: $PackageRoot"
    }

    $packageJsonPath = Join-Path $PackageRoot 'package.json'
    if (-not (Test-Path -LiteralPath $packageJsonPath -PathType Leaf)) {
        throw "Structured attachment package manifest is missing: $packageJsonPath"
    }
    try {
        $package = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Structured attachment package manifest is not valid JSON: $packageJsonPath"
    }
    if ($package.name -ne 'oh-my-opencode-slim' -or $package.version -ne '2.2.8') {
        throw "Structured attachment package identity mismatch: expected oh-my-opencode-slim@2.2.8."
    }

    $expectedDistIndex = '6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A'
    $distIndex = Join-Path $PackageRoot 'dist\index.js'
    Test-RuntimePatchPresence -Path $distIndex -ExpectedAfterHash $expectedDistIndex

    $distIndexContent = Get-Content -LiteralPath $distIndex -Raw
    $requiredSymbols = @(
        'if (msg.info.agent === "observer")',
        'Call observer_attachment with every file path above.',
        'do not use task or read for this handoff.',
        'function createObserverAttachmentTool(options)',
        'files: z7.array(z7.string().min(1)).min(1).max(4)',
        'const imageRoot = path22.resolve(worktree, ".opencode", "images");',
        'const stat = fs9.statSync(absolutePath);',
        'const data = fs9.readFileSync(absolutePath);',
        'body: { parentID, title: "observer-image" }',
        'type: "file"',
        'observer_session_id:',
        'let observerAttachmentTools;',
        'observerAttachmentTools = createObserverAttachmentTool({',
        '...observerAttachmentTools'
    )
    foreach ($requiredSymbol in $requiredSymbols) {
        if (-not $distIndexContent.Contains($requiredSymbol)) {
            throw "Structured attachment symbol is missing from dist/index.js: $requiredSymbol"
        }
    }
}

function Test-OcrPreflight {
    if (-not $SkipRuntimePatchPreflightForMock) {
        Test-RuntimePatchPreflight
    }
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
    $credentialStatus = $credentials -replace "$([char]27)\[[0-9;?]*[ -/]*[@-~]", ''
    $credentialPattern = '(?im)^.*minimax.*\s(?:api|oauth)\s*$'
    Assert-Match -Text $credentialStatus -Pattern $credentialPattern -Message 'No MiniMax credential is available to the managed OpenCode runtime.'

    $models = Invoke-ManagedOpenCode -Arguments @('models', 'minimax-coding-plan', '--verbose')
    $m3Pattern = '(?s)"id": "MiniMax-M3".*?"status": "active".*?"attachment": true.*?"input": \{.*?"image": true'
    Assert-Match -Text $models -Pattern $m3Pattern -Message 'MiniMax-M3 is not an active image-attachment route.'

    'Observer OCR preflight: PASS'
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

Test-OcrPreflight

if ($PreflightOnly) {
    'Observer OCR preflight only: PASS'
    return
}

$ocrToken = [Guid]::NewGuid().ToString('N').Substring(0, 8).ToUpperInvariant()
$ocrCode = "$($ocrToken.Substring(0, 4))-$($ocrToken.Substring(4, 4))"
$imagePath = Join-Path ([System.IO.Path]::GetTempPath()) "observer-attachment-smoke-$PID.png"
try {
    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::new(1200, 360)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $font = [System.Drawing.Font]::new([System.Drawing.FontFamily]::GenericMonospace, 72, [System.Drawing.FontStyle]::Bold)
    try {
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.DrawString($ocrCode, $font, [System.Drawing.Brushes]::Black, 100, 120)
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
    Assert-Match -Text $output -Pattern ([regex]::Escape($ocrCode)) -Message "M3 did not return this run's visual code from the structured image attachment."
    'Observer structured attachment smoke: PASS'
}
finally {
    if (Test-Path -LiteralPath $imagePath) {
        Remove-Item -LiteralPath $imagePath -Force
    }
}
