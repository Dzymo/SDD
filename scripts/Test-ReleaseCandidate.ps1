[CmdletBinding()]
param(
    [string]$Root,
    [string[]]$Versions = @('v0.1.0-rc.1', 'v0.1.0')
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$requiredPaths = @(
    'PACKAGE.md',
    ".github\workflows\release-candidate.yml",
    'scripts\New-ReleaseCandidatePackage.ps1',
    'scripts\Test-ReleaseCandidateAssets.ps1'
)
foreach ($relativePath in $requiredPaths) {
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $Root $relativePath)) -Message "Release source is missing: $relativePath"
}

$workflow = Get-Content -LiteralPath (Join-Path $Root '.github\workflows\release-candidate.yml') -Raw
foreach ($marker in @('workflow_dispatch:', 'contents: write', 'RELEASE_VERSION: ${{ inputs.version }}', "'release', 'create'", '$plan.prerelease', '$releaseArguments += ''--prerelease''', 'Test-ReleaseCandidateAssets.ps1', '-ExpectedPrerelease $plan.prerelease', 'safe_to_cleanup=true', 'Post-release published-asset smoke: PASS', 'git push origin ":refs/tags/$version"')) {
    Assert-True -Condition $workflow.Contains($marker) -Message "Release workflow is missing required marker: $marker"
}
Assert-True -Condition ($workflow -match "(?ms)if:\s*failure\(\)\s*&&\s*steps\.preflight\.outputs\.safe_to_cleanup\s*==\s*'true'.*?gh release delete.*?--cleanup-tag") -Message 'Release workflow must roll back only a release/tag owned by this run.'

foreach ($Version in $Versions) {
    $planPath = Join-Path $Root "release-candidates\$Version.json"
    Assert-True -Condition (Test-Path -LiteralPath $planPath -PathType Leaf) -Message "Release plan is missing: $planPath"
    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    Assert-True -Condition ([string]$plan.version -ceq $Version) -Message 'Release plan version mismatch.'
    Assert-True -Condition ([string]$plan.targetSha -ceq 'a431be0064dc5b84abc31bb60fcbb94eaa185661') -Message 'Release plan target SHA mismatch.'
    Assert-True -Condition ($plan.prerelease -is [bool]) -Message 'Release plan prerelease must be a Boolean.'
    Assert-True -Condition (($Version -match '-rc\.\d+$') -eq [bool]$plan.prerelease) -Message 'Release plan prerelease/version mismatch.'

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "sdd-release-test-$([guid]::NewGuid().ToString('N'))"
    try {
        New-Item -ItemType Directory -Path $tempRoot | Out-Null
        & (Join-Path $Root 'scripts\New-ReleaseCandidatePackage.ps1') -Root $Root -Version $Version -OutputDirectory $tempRoot
        if ($LASTEXITCODE -ne 0) { throw 'Release package script failed.' }
        & (Join-Path $Root 'scripts\Test-ReleaseCandidateAssets.ps1') -AssetDirectory $tempRoot -Version $Version -ExpectedTargetSha $plan.targetSha -ExpectedPrerelease $plan.prerelease -RunSmoke
        if ($LASTEXITCODE -ne 0) { throw 'Release asset verification failed.' }

        $mutationPath = Join-Path $tempRoot "sdd-$Version-source.zip"
        [System.IO.File]::AppendAllText($mutationPath, 'checksum mutation')
        $caughtMutation = $false
        try {
            & (Join-Path $Root 'scripts\Test-ReleaseCandidateAssets.ps1') -AssetDirectory $tempRoot -Version $Version -ExpectedTargetSha $plan.targetSha -ExpectedPrerelease $plan.prerelease
        }
        catch {
            $caughtMutation = $true
        }
        Assert-True -Condition $caughtMutation -Message "Release verifier must reject a mutated $Version artifact."
    }
    finally {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }
}

[Console]::WriteLine('Release packaging behavioral gate: PASS')
