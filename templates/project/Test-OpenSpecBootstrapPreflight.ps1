[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$RequiredVersion = '1.5.0'
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = $PSScriptRoot
}

$failures = @()
$warnings = @()
$reportedDependencies = @{}
$projectRootPath = Resolve-Path -LiteralPath $ProjectRoot -ErrorAction SilentlyContinue
if (-not $projectRootPath) {
    $failures += "Bootstrap project root does not exist: $ProjectRoot"
}
else {
    $ProjectRoot = $projectRootPath.Path
}

$commandDirectory = Join-Path $ProjectRoot '.opencode\commands'
$configPath = Join-Path $ProjectRoot 'openspec\config.yaml'
$expectedCommands = @(
    'opsx-apply.md',
    'opsx-archive.md',
    'opsx-explore.md',
    'opsx-propose.md',
    'opsx-sync.md'
)

if ($projectRootPath) {
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        $failures += "OpenSpec configuration is missing: $configPath"
    }

    if (-not (Test-Path -LiteralPath $commandDirectory -PathType Container)) {
        $failures += "Generated OpenCode command directory is missing: $commandDirectory"
    }
}

$commandFiles = @()
if (Test-Path -LiteralPath $commandDirectory -PathType Container) {
    $commandFiles = @(Get-ChildItem -LiteralPath $commandDirectory -File -Filter 'opsx-*.md')
    $actualCommandNames = @($commandFiles | ForEach-Object { $_.Name })
    foreach ($expectedCommand in $expectedCommands) {
        if ($expectedCommand -notin $actualCommandNames) {
            $failures += "Required generated OpenSpec command is missing: $expectedCommand"
        }
    }
}

$openSpecCommands = @(Get-Command openspec -CommandType Application -ErrorAction SilentlyContinue)
$openSpecCommand = if ($openSpecCommands.Count -gt 0) { $openSpecCommands[0] } else { $null }
if (-not $openSpecCommand) {
    $failures += "OpenSpec CLI is not on PATH. Install @fission-ai/openspec@$RequiredVersion and restart OpenCode."
}
else {
    $versionOutput = @(& openspec --version 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $failures += "OpenSpec CLI failed to report its version: $($versionOutput -join ' ')"
    }
    else {
        $actualVersion = ($versionOutput -join "`n").Trim()
        if ($actualVersion -ne $RequiredVersion) {
            $failures += "OpenSpec CLI version mismatch. Required: $RequiredVersion. Found: $actualVersion. Path: $($openSpecCommand.Source)"
        }
    }
}

$availableCommands = @($commandFiles | ForEach-Object { $_.BaseName })
foreach ($commandFile in $commandFiles) {
    $commandMatches = @(Select-String -LiteralPath $commandFile.FullName -Pattern '/opsx-([a-z0-9-]+)' -AllMatches)
    foreach ($commandMatch in $commandMatches) {
        foreach ($match in $commandMatch.Matches) {
            $dependency = "opsx-$($match.Groups[1].Value)"
            if ($dependency -notin $availableCommands) {
                $dependencyKey = "command:$($commandFile.Name):$dependency"
                if (-not $reportedDependencies.ContainsKey($dependencyKey)) {
                    $warnings += "Unsupported generated command dependency /$dependency in $($commandFile.Name):$($commandMatch.LineNumber). No $dependency.md is included in this bootstrap. Complete missing artifacts with openspec status and openspec instructions."
                    $reportedDependencies[$dependencyKey] = $true
                }
            }
        }
    }

    $skillMatches = @(Select-String -LiteralPath $commandFile.FullName -Pattern '\b(openspec-[a-z0-9]+(?:-[a-z0-9]+)+)\b' -AllMatches)
    foreach ($skillMatch in $skillMatches) {
        foreach ($match in $skillMatch.Matches) {
            $dependency = $match.Groups[1].Value
            $skillPath = Join-Path $ProjectRoot ".opencode\skills\$dependency\SKILL.md"
            if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
                $dependencyKey = "skill:$($commandFile.Name):$dependency"
                if (-not $reportedDependencies.ContainsKey($dependencyKey)) {
                    $warnings += "Unsupported generated skill dependency $dependency in $($commandFile.Name):$($skillMatch.LineNumber). No project-local skill exists at $skillPath."
                    $reportedDependencies[$dependencyKey] = $true
                }
            }
        }
    }

    if ($env:OS -eq 'Windows_NT' -and (Select-String -LiteralPath $commandFile.FullName -Pattern 'mkdir -p' -Quiet)) {
        $warnings += "Windows compatibility warning in $($commandFile.Name): generated POSIX 'mkdir -p' is not idempotent in PowerShell. Use 'openspec archive <change-name>' directly."
    }
}

$warnings = @($warnings | Sort-Object -Unique)
if ($failures.Count -gt 0) {
    $failures | ForEach-Object { "FAIL: $_" }
    $warnings | ForEach-Object { "WARNING: $_" }
    exit 1
}

if ($warnings.Count -gt 0) {
    $warnings | ForEach-Object { "WARNING: $_" }
    'OpenSpec bootstrap preflight: PASS WITH WARNINGS'
    exit 0
}

'OpenSpec bootstrap preflight: PASS'
