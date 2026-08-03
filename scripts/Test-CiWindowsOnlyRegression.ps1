[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

Import-Module (Join-Path $PSScriptRoot 'CiWindowsOnly.psm1') -Force
$fixtureRoot = Join-Path $Root 'fixtures\phase-6\ci-windows-only'
$invalidCases = @(
    @{
        Directory = 'linux-runner'
        Expected = "CI job 'linux-check' in linux-runner.yml must set runs-on: windows-latest; found: ubuntu-latest."
    },
    @{
        Directory = 'missing-runs-on'
        Expected = "CI job 'missing-runner' in missing-runs-on.yml must set runs-on: windows-latest; found: missing."
    },
    @{
        Directory = 'matrix-runner'
        Expected = 'CI job ''matrix-runner'' in matrix-runner.yml must set runs-on: windows-latest; found: ${{ matrix.os }}.'
    },
    @{
        Directory = 'matrix-include'
        Expected = "CI job 'matrix-include-check' in matrix-include.yml uses matrix.include with a non-Windows or unverified runner."
    },
    @{
        Directory = 'reusable-job'
        Expected = "CI reusable job 'reusable-check' in reusable-job.yml cannot prove windows-only because it has no runs-on: windows-latest."
    }
)

foreach ($case in $invalidCases) {
    $failures = @(Get-CiWindowsOnlyFailures -WorkflowDirectory (Join-Path $fixtureRoot $case.Directory))
    if ($case.Expected -notin $failures) {
        throw "Fixture '$($case.Directory)' did not produce its expected Windows-only CI failure. Actual: $($failures -join ' | ')"
    }
}

$validCases = @('valid-windows', 'multi-windows', 'matrix-windows-only', 'matrix-include-windows-only')
foreach ($directory in $validCases) {
    $failures = @(Get-CiWindowsOnlyFailures -WorkflowDirectory (Join-Path $fixtureRoot $directory))
    if ($failures.Count -gt 0) {
        throw "Valid fixture '$directory' produced unexpected Windows-only CI failures: $($failures -join ' | ')"
    }
}

'Windows-only CI workflow fixture regression: PASS'
