[CmdletBinding()]
param(
    [string]$Root,
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    [switch]$SkipSmoke
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

function Invoke-NativeChecked {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

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

Assert-True -Condition ($Version -match '^v\d+\.\d+\.\d+-rc\.\d+$') -Message "Invalid release-candidate version: $Version"

$planPath = Join-Path $Root "release-candidates\$Version.json"
Assert-True -Condition (Test-Path -LiteralPath $planPath -PathType Leaf) -Message "Release plan not found: $planPath"
$plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json

foreach ($field in @('version', 'title', 'targetSha', 'target', 'releaseNotes', 'knownWarnings', 'rollbackPlan', 'externalAction')) {
    $property = $plan.PSObject.Properties[$field]
    Assert-True -Condition ($null -ne $property -and $null -ne $property.Value) -Message "Release plan is missing '$field'."
}
Assert-True -Condition ([string]$plan.version -ceq $Version) -Message "Release plan version '$($plan.version)' does not match '$Version'."
Assert-True -Condition ([string]$plan.targetSha -match '^[0-9a-f]{40}$') -Message 'Release plan targetSha must be a full lowercase Git SHA.'
Assert-True -Condition (@($plan.releaseNotes).Count -gt 0) -Message 'Release plan must contain release notes.'
Assert-True -Condition (@($plan.knownWarnings).Count -gt 0) -Message 'Release plan must contain known warnings.'

$resolvedTarget = (& git -C $Root rev-parse "$($plan.targetSha)^{commit}").Trim()
if ($LASTEXITCODE -ne 0) { throw "Target commit is unavailable: $($plan.targetSha)" }
Assert-True -Condition ($resolvedTarget -ceq [string]$plan.targetSha) -Message "Resolved target '$resolvedTarget' does not match the approved full SHA '$($plan.targetSha)'."

& git -C $Root merge-base --is-ancestor $plan.targetSha HEAD
Assert-True -Condition ($LASTEXITCODE -eq 0) -Message "Target commit $($plan.targetSha) is not an ancestor of the workflow source HEAD."

$outputParent = Split-Path -Parent $OutputDirectory
Assert-True -Condition (Test-Path -LiteralPath $outputParent -PathType Container) -Message "Output parent does not exist: $outputParent"
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}
Assert-True -Condition (@(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -eq 0) -Message "Output directory must be empty: $OutputDirectory"

$safeVersion = $Version
$artifactName = "sdd-$safeVersion-source.zip"
$checksumName = "$artifactName.sha256"
$manifestName = "sdd-$safeVersion-release-manifest.json"
$notesName = "sdd-$safeVersion-release-notes.md"
$artifactPath = Join-Path $OutputDirectory $artifactName
$checksumPath = Join-Path $OutputDirectory $checksumName
$manifestPath = Join-Path $OutputDirectory $manifestName
$notesPath = Join-Path $OutputDirectory $notesName

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "sdd-rc-package-$([guid]::NewGuid().ToString('N'))"
try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    $rawZip = Join-Path $tempRoot 'source.zip'
    $stagingRoot = Join-Path $tempRoot 'staging'
    New-Item -ItemType Directory -Path $stagingRoot | Out-Null

    & git -C $Root archive --format=zip --output=$rawZip $plan.targetSha
    if ($LASTEXITCODE -ne 0) { throw "git archive failed for $($plan.targetSha)." }
    Expand-Archive -LiteralPath $rawZip -DestinationPath $stagingRoot

    foreach ($developmentDirectory in @('.git', '.slim', 'node_modules', 'framework-backups', 'staging')) {
        $developmentPath = Join-Path $stagingRoot $developmentDirectory
        if (Test-Path -LiteralPath $developmentPath) {
            Remove-Item -LiteralPath $developmentPath -Recurse -Force
        }
    }

    $blockedFiles = @(Get-ChildItem -LiteralPath $stagingRoot -File -Recurse -Force | Where-Object {
        $_.Name -match '^\.env(?:\..*)?$' -or
        $_.Extension -match '^\.(?:pem|key|p12|pfx|log)$'
    })
    $blockedFileNames = @($blockedFiles | ForEach-Object { $_.FullName }) -join ', '
    Assert-True -Condition ($blockedFiles.Count -eq 0) -Message "Packaged source contains blocked file names: $blockedFileNames"

    $blockedDirectories = @(Get-ChildItem -LiteralPath $stagingRoot -Directory -Recurse -Force | Where-Object {
        $_.Name -in @('.git', '.slim', 'node_modules', 'framework-backups', 'staging')
    })
    $blockedDirectoryNames = @($blockedDirectories | ForEach-Object { $_.FullName }) -join ', '
    Assert-True -Condition ($blockedDirectories.Count -eq 0) -Message "Packaged source contains blocked directories: $blockedDirectoryNames"

    $manifest = [ordered]@{
        schemaVersion = 1
        version = [string]$plan.version
        title = [string]$plan.title
        targetSha = [string]$plan.targetSha
        target = [string]$plan.target
        artifact = $artifactName
        releaseNotes = @($plan.releaseNotes)
        knownWarnings = @($plan.knownWarnings)
        rollbackPlan = [string]$plan.rollbackPlan
        externalAction = [string]$plan.externalAction
        generatedAtUtc = [DateTime]::UtcNow.ToString('o')
        smokeCommands = @(
            'scripts\Test-FrameworkSkeleton.ps1',
            'scripts\Test-CiWindowsOnlyRegression.ps1',
            'scripts\Test-PackagingRelease.ps1'
        )
    }
    $manifestJson = $manifest | ConvertTo-Json -Depth 10
    $manifestJson | Set-Content -LiteralPath (Join-Path $stagingRoot 'RELEASE-MANIFEST.json') -Encoding UTF8
    $manifestJson | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    if (-not $SkipSmoke) {
        foreach ($testScript in $manifest.smokeCommands) {
            $testPath = Join-Path $stagingRoot $testScript
            Assert-True -Condition (Test-Path -LiteralPath $testPath -PathType Leaf) -Message "Smoke script missing from packaged source: $testScript"
            Invoke-NativeChecked -FilePath 'PowerShell.exe' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $testPath) -WorkingDirectory $stagingRoot
        }
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($stagingRoot, $artifactPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    $sha256 = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
    "$sha256 *$artifactName" | Set-Content -LiteralPath $checksumPath -Encoding ASCII

    $notes = @(
        "# $($plan.title)",
        '',
        "Target commit: ``$($plan.targetSha)``",
        '',
        '## Release Notes',
        ''
    )
    $notes += @($plan.releaseNotes | ForEach-Object { "- $_" })
    $notes += @('', '## Known Warnings', '')
    $notes += @($plan.knownWarnings | ForEach-Object { "- $_" })
    $notes += @('', '## Rollback', '', [string]$plan.rollbackPlan)
    $notes | Set-Content -LiteralPath $notesPath -Encoding UTF8

    [Console]::WriteLine("Release candidate package: $artifactPath")
    [Console]::WriteLine("SHA-256: $sha256")
    [Console]::WriteLine('Release candidate package gate: PASS')
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
