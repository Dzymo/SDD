param(
    [string]$ResultsPath = (Join-Path $PSScriptRoot '..\results.json')
)

$required = @(
    'm3-none',
    'm3-thinking',
    'terra-default',
    'terra-high',
    'sol-default',
    'sol-high'
)
$expectedStatus = @{
    'm3-none' = 'completed'
    'm3-thinking' = 'completed'
    'terra-default' = 'completed'
    'terra-high' = 'completed'
    'sol-default' = 'completed'
    'sol-high' = 'completed'
}

if (-not (Test-Path -LiteralPath $ResultsPath)) {
    throw "Results file not found: $ResultsPath"
}

$results = Get-Content -LiteralPath $ResultsPath -Raw | ConvertFrom-Json
$seen = @{}
$failures = @()

foreach ($result in @($results)) {
    $seen[$result.condition] = $true
    if ($result.status -ne $expectedStatus[$result.condition]) {
        $failures += "$($result.condition): expected status $($expectedStatus[$result.condition]), got $($result.status)"
        continue
    }

    try {
        $response = $result.response | ConvertFrom-Json
    }
    catch {
        $failures += "$($result.condition): response is not parseable JSON"
        continue
    }

    $keys = @($response.PSObject.Properties.Name | Sort-Object)
    $expectedKeys = @('ask_user', 'decision', 'delegate', 'reason', 'verification', 'worktree')
    if (Compare-Object -ReferenceObject $expectedKeys -DifferenceObject $keys) {
        $failures += "$($result.condition): response keys do not match the contract"
    }
    if ($response.decision -ne 'direct-execution') { $failures += "$($result.condition): incorrect decision" }
    if ($response.delegate -ne $false) { $failures += "$($result.condition): delegation was not false" }
    if ($response.ask_user -ne $false) { $failures += "$($result.condition): ask_user was not false" }
    if ($response.worktree -ne $false) { $failures += "$($result.condition): worktree was not false" }
    if ($response.verification -ne 'rg -n "recieve|receive" README.md') {
        $failures += "$($result.condition): incorrect verification command"
    }
}

foreach ($condition in $required) {
    if (-not $seen.ContainsKey($condition)) {
        $failures += "Missing condition: $condition"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { "FAIL: $_" }
    exit 1
}

'Phase 1 rerun contract: PASS'
