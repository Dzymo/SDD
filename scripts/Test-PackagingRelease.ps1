[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-NativeChecked {
    param([string]$FilePath, [string[]]$Arguments, [string]$Description)

    $output = & $FilePath @Arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE.`n$output"
    }
    return $output
}

function Get-ReleaseVerdict {
    param([object]$Scenario)

    $package = $Scenario.package
    if ($package.buildExitCode -ne 0) { return 'PACKAGE-BUILD-FAILED' }
    if ($package.artifactPresent -ne $true) { return 'ARTIFACT-MISSING' }
    if ($package.versionMatches -ne $true) { return 'VERSION-MISMATCH' }
    if ($package.cleanSmokeExitCode -ne 0) { return 'CLEAN-SMOKE-FAILED' }
    if ($package.contentCheck -ne 'clean') { return 'CONTENT-CHECK-FAILED' }
    if ([string]::IsNullOrWhiteSpace($package.sha256)) { return 'CHECKSUM-MISSING' }

    $release = $Scenario.release
    if ([string]::IsNullOrWhiteSpace($release.externalAction)) { return 'EXTERNAL-ACTION-MISSING' }
    foreach ($field in @('version', 'releaseNotes', 'target', 'knownWarnings', 'rollbackPlan', 'externalAction', 'record')) {
        if ($null -eq $release.approval -or [string]::IsNullOrWhiteSpace($release.approval.$field)) {
            return 'RELEASE-APPROVAL-REQUIRED'
        }
    }
    if ($release.approval.externalAction -ne $release.externalAction) { return 'RELEASE-APPROVAL-REQUIRED' }
    if ($null -eq $release.externalResult) { return 'RELEASE-AUTHORIZED' }
    if ($release.externalResult.exitCode -ne 0 -or $release.externalResult.postReleaseSmokeExitCode -ne 0) { return 'EXTERNAL-RELEASE-FAILED' }
    if ($null -eq $release.openspec -or $release.openspec.strictValidationExitCode -ne 0) { return 'ARCHIVE-BLOCKED' }
    if ($release.openspec.archiveExitCode -ne 0) { return 'ARCHIVE-FAILED' }
    return 'RELEASE-ARCHIVED'
}

# Verdict expectations and fixed scenario coverage are owned by code.
$requiredPhase10Scenarios = [ordered]@{
    'clean-package-needs-approval'               = @{ expected = 'RELEASE-APPROVAL-REQUIRED' }
    'clean-package-authorized-but-not-executed'  = @{ expected = 'RELEASE-AUTHORIZED' }
    'clean-smoke-failure-blocks-release'         = @{ expected = 'CLEAN-SMOKE-FAILED' }
    'content-finding-blocks-release'             = @{ expected = 'CONTENT-CHECK-FAILED' }
    'successful-release-can-be-archived'         = @{ expected = 'RELEASE-ARCHIVED' }
}

function Test-Phase10ScenarioSet {
    param(
        [object]$Scenarios,
        [string]$SourceLabel
    )

    $scenarioArray = @($Scenarios)
    if ($scenarioArray.Count -eq 0) {
        throw "$SourceLabel contains no scenarios; Phase 10 coverage must be non-empty."
    }

    $names = @($scenarioArray | ForEach-Object { [string]$_.name })
    foreach ($entry in $names) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            throw "$SourceLabel contains a scenario with an empty name."
        }
    }
    $duplicateNames = @($names | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($duplicateNames.Count -gt 0) {
        throw "$SourceLabel has duplicate scenario names: $($duplicateNames -join ', ')."
    }

    $requiredNames = @($requiredPhase10Scenarios.Keys)
    $missingNames = @($requiredNames | Where-Object { $_ -notin $names })
    if ($missingNames.Count -gt 0) {
        throw "$SourceLabel is missing required scenarios: $($missingNames -join ', ')."
    }
    $unexpectedNames = @($names | Where-Object { $_ -notin $requiredNames })
    if ($unexpectedNames.Count -gt 0) {
        throw "$SourceLabel has unexpected scenarios: $($unexpectedNames -join ', ')."
    }

    foreach ($scenario in $scenarioArray) {
        $name = [string]$scenario.name
        $requiredSpec = $requiredPhase10Scenarios[$name]
        if ($null -eq $requiredSpec) {
            throw "$SourceLabel references an unknown scenario: '$name'."
        }
        $actual = Get-ReleaseVerdict -Scenario $scenario
        if ($actual -cne $requiredSpec.expected) {
            throw "$SourceLabel scenario '$name' got verdict '$actual'; expected '$($requiredSpec.expected)'."
        }
    }
}

$guidePath = Join-Path $Root 'docs\packaging-and-release.md'
$skillPath = Join-Path $Root 'skills\package-and-release\SKILL.md'
$promptPath = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'
$packageTemplatePath = Join-Path $Root 'templates\project\PACKAGE.md'
$verificationTemplatePath = Join-Path $Root 'templates\openspec\verification.md'
$releaseTemplatePath = Join-Path $Root 'templates\openspec\release.md'
$fixturePath = Join-Path $Root 'fixtures\phase-10\release-scenarios.json'
$packageFixturePath = Join-Path $Root 'fixtures\phase-10\clean-package'
$applyPath = Join-Path $Root 'scripts\Apply-PackagingRelease.ps1'
$runtimePath = Join-Path $Root 'scripts\Test-PackagingReleaseRuntime.ps1'

foreach ($path in @($guidePath, $skillPath, $promptPath, $packageTemplatePath, $verificationTemplatePath, $releaseTemplatePath, $fixturePath, $packageFixturePath, $applyPath, $runtimePath)) {
    Assert-True -Condition (Test-Path -LiteralPath $path) -Message "Required Phase 10 source not found: $path"
}

try {
    $scenarios = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Invalid Phase 10 release fixture. $($_.Exception.Message)"
}

Test-Phase10ScenarioSet -Scenarios $scenarios -SourceLabel 'fixtures/phase-10/release-scenarios.json'

# Negative mutation: a fixture set with a duplicate scenario must be rejected.
$duplicateScenarios = @($scenarios) + @($scenarios | Select-Object -First 1)
$caughtDuplicate = $false
try {
    Test-Phase10ScenarioSet -Scenarios $duplicateScenarios -SourceLabel 'mutation:duplicate'
} catch {
    $caughtDuplicate = $true
}
Assert-True -Condition $caughtDuplicate -Message 'Phase 10 gate must reject a fixture set that contains a duplicate scenario name.'

# Negative mutation: a fixture set missing a required scenario must be rejected.
$missingScenarios = @($scenarios | Where-Object { [string]$_.name -ne 'clean-package-needs-approval' })
$caughtMissing = $false
try {
    Test-Phase10ScenarioSet -Scenarios $missingScenarios -SourceLabel 'mutation:missing'
} catch {
    $caughtMissing = $true
}
Assert-True -Condition $caughtMissing -Message 'Phase 10 gate must reject a fixture set that is missing a required scenario.'

# Negative mutation: a clean artifact that bypasses explicit approval must be rejected.
$sourceForMutation = @($scenarios | Where-Object { [string]$_.name -eq 'successful-release-can-be-archived' })[0]
$mutationJson = $sourceForMutation | ConvertTo-Json -Depth 20
# Strip the externalResult so the scenario collapses back to RELEASE-AUTHORIZED.
$mutatedJson = $mutationJson -replace '"externalResult":\s*\{[^}]*\},?\s*', ''
$clone = $mutatedJson | ConvertFrom-Json
$clonedVerdict = Get-ReleaseVerdict -Scenario $clone
Assert-True -Condition ($clonedVerdict -ceq 'RELEASE-AUTHORIZED') -Message 'Phase 10 gate must reject an authorized-but-unexecuted release as RELEASE-AUTHORIZED (not RELEASE-ARCHIVED).'

foreach ($required in @('node', 'npm')) {
    $command = Get-Command -Name $required -ErrorAction SilentlyContinue
    Assert-True -Condition ($null -ne $command) -Message "Phase 10 clean-package fixture requires '$required' on PATH."
}

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "sdd-phase-10-$([guid]::NewGuid().ToString('N'))"
try {
    $sourceRoot = Join-Path $temporaryRoot 'source'
    $cleanRoot = Join-Path $temporaryRoot 'clean'
    New-Item -ItemType Directory -Path $temporaryRoot -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath $packageFixturePath -Destination $sourceRoot -Recurse -ErrorAction Stop

    Push-Location -LiteralPath $sourceRoot
    try {
        $packOutput = @(& npm pack --json --ignore-scripts)
        $packExitCode = $LASTEXITCODE
        Assert-True -Condition ($packExitCode -eq 0) -Message "Fixture package command failed with exit code $packExitCode."
    }
    finally {
        Pop-Location
    }
    $packed = ($packOutput -join [Environment]::NewLine) | ConvertFrom-Json -ErrorAction Stop
    $packedArtifacts = @()
    if ($null -ne $packed.filename) {
        $packedArtifacts = @($packed)
    }
    elseif ($packed -is [System.Array]) {
        $packedArtifacts = @($packed)
    }
    else {
        $packedArtifacts = @($packed.PSObject.Properties | ForEach-Object { $_.Value })
    }
    Assert-True -Condition ($packedArtifacts.Count -eq 1) -Message 'Fixture package command must produce exactly one artifact.'
    $packedArtifact = $packedArtifacts[0]
    $artifactFilename = [string]$packedArtifact.filename
    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($artifactFilename)) -Message "Fixture package report has no filename. Report type: $($packedArtifact.GetType().FullName); properties: $((@($packedArtifact.PSObject.Properties.Name) -join ', ')); stdout length: $(($packOutput -join [Environment]::NewLine).Length)"
    $artifact = Join-Path $sourceRoot $artifactFilename
    Assert-True -Condition (Test-Path -LiteralPath $artifact -PathType Leaf) -Message "Fixture artifact was not created: $artifact"
    Assert-True -Condition ($packedArtifact.version -eq '1.0.0') -Message 'Fixture artifact version does not match the intended version.'
    $checksum = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash
    Assert-True -Condition ($checksum -match '^[A-F0-9]{64}$') -Message 'Fixture artifact SHA-256 was not recorded in the expected format.'

    New-Item -ItemType Directory -Path $cleanRoot -ErrorAction Stop | Out-Null
    Push-Location -LiteralPath $cleanRoot
    try {
        Invoke-NativeChecked -FilePath 'npm' -Arguments @('install', '--ignore-scripts', '--no-audit', '--no-fund', $artifact) -Description 'Clean fixture install' | Out-Null
        Invoke-NativeChecked -FilePath 'node' -Arguments @('-e', "const fixture = require('@sdd/phase-10-clean-fixture'); if (fixture.smoke() !== 'phase-10-clean-smoke') process.exit(1);") -Description 'Clean fixture smoke' | Out-Null
    }
    finally {
        Pop-Location
    }

    $installedPackage = Join-Path $cleanRoot 'node_modules\@sdd\phase-10-clean-fixture'
    Assert-True -Condition (Test-Path -LiteralPath $installedPackage -PathType Container) -Message 'Clean install did not create the expected package directory.'
    $forbiddenName = '(?i)(^|[._-])(secret|token|credential|password|apikey|api-key|private-key)([._-]|$)|(^|[._-])env([._-]|$)'
    $contentPatterns = @(
        '-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----',
        '(?i)(?:api[_-]?key|access[_-]?token|secret|password)\s*[=:]\s*["'']?[A-Za-z0-9_+/-]{16,}'
    )
    foreach ($file in @(Get-ChildItem -LiteralPath $installedPackage -File -Recurse -Force)) {
        Assert-True -Condition ($file.Name -notmatch $forbiddenName) -Message "Installed fixture contains prohibited file name: $($file.Name)"
        $content = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($pattern in $contentPatterns) {
            Assert-True -Condition ($content -notmatch $pattern) -Message "Installed fixture contains prohibited content in: $($file.Name)"
        }
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$requiredContent = @{
    $guidePath = @('Package Contract', 'Clean install/run', 'Explicit Release Approval', 'OpenSpec Archive And Rollback')
    $skillPath = @('`PACKAGE.md`', 'explicit user approval', 'Never perform an external release', 'Do not bypass archive validation')
    $promptPath = @('Package And Release', 'release-ready', 'explicit user approval', 'strict OpenSpec validation and archive')
    $packageTemplatePath = @('Package/build command', 'Clean Environment Smoke', 'SHA-256', 'Rollback')
    $verificationTemplatePath = @('Package Evidence', 'Clean install/run', 'SHA-256')
    $releaseTemplatePath = @('Explicit User Approval', 'Exact external action', 'OpenSpec Archive', 'rollback')
    $applyPath = @('SupportsShouldProcess', 'Get-FileHashOrAbsent', 'Restore-Target', 'manifest.json', 'changed targets were restored')
    $runtimePath = @('debug', 'Package And Release', 'package-and-release', 'Managed OpenCode')
}
foreach ($path in $requiredContent.Keys) {
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($rule in $requiredContent[$path]) {
        Assert-True -Condition $content.Contains($rule) -Message "$path is missing required Phase 10 rule: $rule"
    }
}

'Phase 10 packaging and release: PASS'
