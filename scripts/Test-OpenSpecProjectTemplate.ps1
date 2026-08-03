[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$fixtureRoot = Join-Path $Root 'fixtures\phase-6\valid-project'
if (-not (Test-Path -LiteralPath $fixtureRoot -PathType Container)) {
    throw "OpenSpec fixture is missing: $fixtureRoot"
}

Push-Location -LiteralPath $fixtureRoot
try {
    & npx --yes '@fission-ai/openspec@1.5.0' validate 'add-status-endpoint' '--strict' '--no-interactive'
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSpec strict validation failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

'OpenSpec project template fixture strict validation: PASS'
