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

function Assert-PreflightFailure {
    param(
        [string]$Name,
        [string[]]$SmokeArguments,
        [string]$ExpectedMessage,
        [string]$CredentialSentinel
    )

    $output = & $script:PowerShell -NoProfile -ExecutionPolicy Bypass -File $script:Smoke @SmokeArguments 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    Assert-True -Condition ($exitCode -ne 0) -Message "$Name unexpectedly passed preflight."
    Assert-True -Condition ($output.Contains($ExpectedMessage)) -Message "$Name did not report the expected preflight failure."
    Assert-True -Condition (-not $output.Contains($CredentialSentinel)) -Message "$Name leaked the credential sentinel."
}

function New-MockManagedCli {
    param(
        [string]$Path,
        [string]$Config,
        [string]$Credentials,
        [string]$Models,
        [switch]$FailDebug
    )

    $debugLines = if ($FailDebug) {
        @('echo CREDENTIAL_SENTINEL_DO_NOT_LEAK', 'exit /b 9')
    }
    else {
        @("echo $Config", 'exit /b 0')
    }

    $lines = @(
        '@echo off',
        'if /I "%~1 %~2"=="debug config" ('
    ) + $debugLines + @(
        ')',
        'if /I "%~1 %~2"=="auth list" (',
        "echo $Credentials",
        'exit /b 0',
        ')',
        'if /I "%~1 %~2 %~3"=="models minimax-coding-plan --verbose" (',
        "echo $Models",
        'exit /b 0',
        ')',
        'exit /b 1'
    )
    Set-Content -LiteralPath $Path -Value $lines -Encoding Ascii
}

$credentialSentinel = 'CREDENTIAL_SENTINEL_DO_NOT_LEAK'
$validConfig = '{ "agent": { "orchestrator": { "prompt": "observer_attachment" }, "observer": { "model": "minimax-coding-plan/MiniMax-M3", "prompt": "structured attachments" } } }'
$validModels = '{ "id": "MiniMax-M3", "status": "active", "attachment": true, "input": { "image": true } }'
$validCredentials = 'MiniMax Token Plan minimax.io api'
$smoke = Join-Path $Root 'scripts\Test-ObserverAttachment.ps1'
$powerShellExecutable = if ($PSVersionTable.PSEdition -eq 'Core') {
    'pwsh.exe'
}
else {
    'powershell.exe'
}
$PowerShell = Join-Path $PSHOME $powerShellExecutable

if (-not (Test-Path -LiteralPath $smoke)) {
    throw "Smoke script not found: $smoke"
}
if (-not (Test-Path -LiteralPath $PowerShell)) {
    throw "PowerShell executable not found: $PowerShell"
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "observer-preflight-negative-$PID"
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    $mock = Join-Path $tempRoot 'managed.cmd'
    $workspace = Join-Path $tempRoot 'workspace'
    New-Item -ItemType Directory -Path $workspace -Force | Out-Null

    $mockPreflightArguments = @('-PreflightOnly', '-SkipRuntimePatchPreflightForMock')

    Assert-PreflightFailure -Name 'Missing managed binary' -SmokeArguments (@('-Managed', (Join-Path $tempRoot 'missing.exe'), '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'Managed OpenCode binary not found:' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config $validConfig -Credentials $validCredentials -Models $validModels
    Assert-PreflightFailure -Name 'Missing workspace' -SmokeArguments (@('-Managed', $mock, '-Workspace', (Join-Path $tempRoot 'missing-workspace')) + $mockPreflightArguments) -ExpectedMessage 'Smoke workspace not found:' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config $validConfig -Credentials $validCredentials -Models $validModels -FailDebug
    Assert-PreflightFailure -Name 'Failed runtime config command' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'Managed OpenCode preflight command failed: debug config' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config '{' -Credentials $validCredentials -Models $validModels
    Assert-PreflightFailure -Name 'Invalid runtime config' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'Managed OpenCode did not return valid effective JSON.' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config '{ "agent": { "orchestrator": { "prompt": "observer_attachment" } } }' -Credentials $validCredentials -Models $validModels
    Assert-PreflightFailure -Name 'Disabled Observer' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'Observer is not enabled in the effective managed runtime.' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config '{ "agent": { "orchestrator": { "prompt": "observer_attachment" }, "observer": { "model": "other/model", "prompt": "structured attachments" } } }' -Credentials $validCredentials -Models $validModels
    Assert-PreflightFailure -Name 'Wrong Observer model' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'Observer is not routed to MiniMax-M3 in the effective managed runtime.' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config '{ "agent": { "orchestrator": { "prompt": "path-only" }, "observer": { "model": "minimax-coding-plan/MiniMax-M3", "prompt": "structured attachments" } } }' -Credentials $validCredentials -Models $validModels
    Assert-PreflightFailure -Name 'Missing Orchestrator contract' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'The effective Orchestrator prompt does not route images through observer_attachment.' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config '{ "agent": { "orchestrator": { "prompt": "observer_attachment" }, "observer": { "model": "minimax-coding-plan/MiniMax-M3", "prompt": "path only" } } }' -Credentials $validCredentials -Models $validModels
    Assert-PreflightFailure -Name 'Missing Observer contract' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'The effective Observer prompt does not accept structured attachments.' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config $validConfig -Credentials 'MiniMax Token Plan minimax.io' -Models $validModels
    Assert-PreflightFailure -Name 'Provider name without credential' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'No MiniMax credential is available to the managed OpenCode runtime.' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config $validConfig -Credentials $credentialSentinel -Models $validModels
    Assert-PreflightFailure -Name 'Missing MiniMax credential' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'No MiniMax credential is available to the managed OpenCode runtime.' -CredentialSentinel $credentialSentinel

    New-MockManagedCli -Path $mock -Config $validConfig -Credentials $validCredentials -Models '{ "id": "MiniMax-M3", "status": "inactive", "attachment": false, "input": { "image": false } }'
    Assert-PreflightFailure -Name 'Inactive M3 image route' -SmokeArguments (@('-Managed', $mock, '-Workspace', $workspace) + $mockPreflightArguments) -ExpectedMessage 'MiniMax-M3 is not an active image-attachment route.' -CredentialSentinel $credentialSentinel

    'Observer OCR preflight negative tests: PASS'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

exit 0
