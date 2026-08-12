[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AssetDirectory,
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedTargetSha,
    [Parameter(Mandatory = $true)]
    [bool]$ExpectedPrerelease,
    [switch]$RunSmoke
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-NativeChecked {
    param([string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory)
    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

$artifactName = "sdd-$Version-source.zip"
$checksumName = "$artifactName.sha256"
$manifestName = "sdd-$Version-release-manifest.json"
$artifactPath = Join-Path $AssetDirectory $artifactName
$checksumPath = Join-Path $AssetDirectory $checksumName
$manifestPath = Join-Path $AssetDirectory $manifestName

foreach ($path in @($artifactPath, $checksumPath, $manifestPath)) {
    Assert-True -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "Required release asset is missing: $path"
}

$checksumLine = (Get-Content -LiteralPath $checksumPath -Raw).Trim()
$expectedPattern = '^([0-9a-f]{64}) \*' + [regex]::Escape($artifactName) + '$'
Assert-True -Condition ($checksumLine -match $expectedPattern) -Message "Invalid checksum file: $checksumLine"
$actualHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
Assert-True -Condition ($actualHash -ceq $Matches[1]) -Message "Artifact SHA-256 mismatch. Expected $($Matches[1]); found $actualHash."

$externalManifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Assert-True -Condition ([string]$externalManifest.version -ceq $Version) -Message 'External manifest version mismatch.'
$externalPrerelease = $externalManifest.PSObject.Properties['prerelease']
if ($null -eq $externalPrerelease) {
    Assert-True -Condition ($ExpectedPrerelease -and $Version -match '-rc\.\d+$') -Message 'External manifest is missing prerelease metadata.'
}
else {
    Assert-True -Condition ([bool]$externalPrerelease.Value -eq $ExpectedPrerelease) -Message 'External manifest prerelease mismatch.'
}
Assert-True -Condition ([string]$externalManifest.targetSha -ceq $ExpectedTargetSha) -Message 'External manifest target SHA mismatch.'
Assert-True -Condition ([string]$externalManifest.artifact -ceq $artifactName) -Message 'External manifest artifact name mismatch.'

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "sdd-release-assets-$([guid]::NewGuid().ToString('N'))"
try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    Expand-Archive -LiteralPath $artifactPath -DestinationPath $tempRoot
    $internalManifestPath = Join-Path $tempRoot 'RELEASE-MANIFEST.json'
    Assert-True -Condition (Test-Path -LiteralPath $internalManifestPath -PathType Leaf) -Message 'Packaged source is missing RELEASE-MANIFEST.json.'
    $internalManifest = Get-Content -LiteralPath $internalManifestPath -Raw | ConvertFrom-Json
    Assert-True -Condition ([string]$internalManifest.version -ceq $Version) -Message 'Internal manifest version mismatch.'
    $internalPrerelease = $internalManifest.PSObject.Properties['prerelease']
    if ($null -eq $internalPrerelease) {
        Assert-True -Condition ($ExpectedPrerelease -and $Version -match '-rc\.\d+$') -Message 'Internal manifest is missing prerelease metadata.'
    }
    else {
        Assert-True -Condition ([bool]$internalPrerelease.Value -eq $ExpectedPrerelease) -Message 'Internal manifest prerelease mismatch.'
    }
    Assert-True -Condition ([string]$internalManifest.targetSha -ceq $ExpectedTargetSha) -Message 'Internal manifest target SHA mismatch.'
    Assert-True -Condition (($internalManifest | ConvertTo-Json -Depth 10 -Compress) -ceq ($externalManifest | ConvertTo-Json -Depth 10 -Compress)) -Message 'Internal and external release manifests differ.'

    if ($RunSmoke) {
        foreach ($relativePath in @(
            'scripts\Test-FrameworkSkeleton.ps1',
            'scripts\Test-CiWindowsOnlyRegression.ps1',
            'scripts\Test-PackagingRelease.ps1'
        )) {
            $testPath = Join-Path $tempRoot $relativePath
            Assert-True -Condition (Test-Path -LiteralPath $testPath -PathType Leaf) -Message "Published source is missing smoke script: $relativePath"
            Invoke-NativeChecked -FilePath 'PowerShell.exe' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $testPath) -WorkingDirectory $tempRoot
        }
    }

    [Console]::WriteLine('Release asset verification: PASS')
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
