[CmdletBinding()]
param(
    [string]$Root
)

Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) {
        throw $Message
    }
}

function Get-TestHash {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Write-TestJson {
    param([string]$Path, [object]$Value)

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    $json = $Value | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function New-TargetConfig {
    return [ordered]@{
        preset = 'sdd-personal'
        customTopLevel = 'preserve-top-level'
        presets = [ordered]@{
            'sdd-personal' = [ordered]@{
                fixer = [ordered]@{
                    model = @(
                        [ordered]@{ id = 'custom/fixer'; variant = 'custom' }
                    )
                    skills = @('legacy-skill')
                    customFixerField = 'preserve-fixer'
                }
                customAgent = [ordered]@{
                    model = 'custom/agent'
                }
            }
            'user-preset' = [ordered]@{
                sentinel = 'preserve-user-preset'
            }
        }
        customObject = [ordered]@{
            sentinel = 'preserve-object'
        }
    }
}

function Invoke-ApplyTest {
    param(
        [string]$PluginTarget,
        [string]$OrchestratorPromptTarget,
        [string]$FixerPromptTarget,
        [string]$OraclePromptTarget,
        [string]$DebuggingSkillTarget,
        [string]$VerificationSkillTarget,
        [string]$BackupRoot
    )

    # The production apply invokes legacy source gates that intentionally run
    # without StrictMode; isolate that behavior from this test's own StrictMode.
    Set-StrictMode -Off

    function Get-Process {
        [CmdletBinding()]
        param()

        return @()
    }

    try {
        $output = & $script:ApplyScript `
            -Root $script:FrameworkRoot `
            -PluginTarget $PluginTarget `
            -OrchestratorPromptTarget $OrchestratorPromptTarget `
            -FixerPromptTarget $FixerPromptTarget `
            -OraclePromptTarget $OraclePromptTarget `
            -DebuggingSkillTarget $DebuggingSkillTarget `
            -VerificationSkillTarget $VerificationSkillTarget `
            -BackupRoot $BackupRoot `
            -Confirm:$false 2>&1 | Out-String
        $exitCode = 0
    }
    catch {
        $output = ($_ | Out-String)
        $exitCode = 1
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output
    }
}

$FrameworkRoot = $Root
$ApplyScript = Join-Path $Root 'scripts\Apply-ExecutionVerification.ps1'
Assert-True -Condition (Test-Path -LiteralPath $ApplyScript -PathType Leaf) -Message "Phase 7 apply script not found: $ApplyScript"

$sourceConfigPath = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$sourceConfig = Get-Content -LiteralPath $sourceConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
$expectedSkills = @($sourceConfig.presets.'sdd-personal'.fixer.skills)

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "phase-7-apply-test-$([guid]::NewGuid().ToString('N'))"
try {
    New-Item -ItemType Directory -Path $temporaryRoot -ErrorAction Stop | Out-Null

    $successRoot = Join-Path $temporaryRoot 'success'
    $successBackupRoot = Join-Path $successRoot 'backups'
    New-Item -ItemType Directory -Path $successBackupRoot -Force -ErrorAction Stop | Out-Null
    $successPlugin = Join-Path $successRoot 'config\oh-my-opencode-slim.json'
    $successOrchestrator = Join-Path $successRoot 'config\prompts\orchestrator.md'
    $successFixer = Join-Path $successRoot 'config\prompts\fixer.md'
    $successOracle = Join-Path $successRoot 'config\prompts\oracle.md'
    $successDebugging = Join-Path $successRoot 'config\skills\systematic-debugging\SKILL.md'
    $successVerification = Join-Path $successRoot 'config\skills\verification-before-completion\SKILL.md'
    Write-TestJson -Path $successPlugin -Value (New-TargetConfig)
    $successBeforeHash = Get-TestHash -Path $successPlugin

    $successResult = Invoke-ApplyTest `
        -PluginTarget $successPlugin `
        -OrchestratorPromptTarget $successOrchestrator `
        -FixerPromptTarget $successFixer `
        -OraclePromptTarget $successOracle `
        -DebuggingSkillTarget $successDebugging `
        -VerificationSkillTarget $successVerification `
        -BackupRoot $successBackupRoot
    Assert-True -Condition ($successResult.ExitCode -eq 0) -Message "Phase 7 isolated apply failed.`n$($successResult.Output)"
    Assert-True -Condition ($successResult.Output.Contains('Phase 7 execution and verification layer applied.')) -Message 'Phase 7 isolated apply did not report success.'

    $mergedConfig = Get-Content -LiteralPath $successPlugin -Raw | ConvertFrom-Json -ErrorAction Stop
    Assert-True -Condition ($mergedConfig.customTopLevel -eq 'preserve-top-level') -Message 'Phase 7 merge removed a top-level custom property.'
    Assert-True -Condition ($mergedConfig.customObject.sentinel -eq 'preserve-object') -Message 'Phase 7 merge changed an unrelated top-level object.'
    Assert-True -Condition ($mergedConfig.presets.'user-preset'.sentinel -eq 'preserve-user-preset') -Message 'Phase 7 merge removed an unrelated preset.'
    Assert-True -Condition ($mergedConfig.presets.'sdd-personal'.customAgent.model -eq 'custom/agent') -Message 'Phase 7 merge removed an unrelated agent override.'
    Assert-True -Condition ($mergedConfig.presets.'sdd-personal'.fixer.customFixerField -eq 'preserve-fixer') -Message 'Phase 7 merge removed an unrelated Fixer property.'
    Assert-True -Condition ($mergedConfig.presets.'sdd-personal'.fixer.model[0].id -eq 'custom/fixer') -Message 'Phase 7 merge changed the existing Fixer model.'
    Assert-True -Condition ((@($mergedConfig.presets.'sdd-personal'.fixer.skills) -join '|') -eq ($expectedSkills -join '|')) -Message 'Phase 7 merge did not apply only the reviewed Fixer skills.'
    Assert-True -Condition ((Get-TestHash -Path $successPlugin) -ne (Get-TestHash -Path $sourceConfigPath)) -Message 'Phase 7 merge replaced the full target config with the source config.'

    $sourceTargetPairs = @(
        [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'); Target = $successOrchestrator },
        [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\fixer.md'); Target = $successFixer },
        [pscustomobject]@{ Source = (Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal\oracle.md'); Target = $successOracle },
        [pscustomobject]@{ Source = (Join-Path $Root 'skills\systematic-debugging\SKILL.md'); Target = $successDebugging },
        [pscustomobject]@{ Source = (Join-Path $Root 'skills\verification-before-completion\SKILL.md'); Target = $successVerification }
    )
    foreach ($pair in $sourceTargetPairs) {
        Assert-True -Condition ((Get-TestHash -Path $pair.Source) -eq (Get-TestHash -Path $pair.Target)) -Message "Phase 7 isolated apply target differs from source: $($pair.Target)"
    }

    $successBackupDirectories = @(Get-ChildItem -LiteralPath $successBackupRoot -Directory -Filter 'phase-7-*')
    Assert-True -Condition ($successBackupDirectories.Count -eq 1) -Message 'Phase 7 isolated apply must create exactly one backup directory.'
    $manifestPath = Join-Path $successBackupDirectories[0].FullName 'manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -ErrorAction Stop
    Assert-True -Condition (@($manifest.entries).Count -eq 6) -Message 'Phase 7 manifest must contain all six target entries.'
    $pluginEntry = @($manifest.entries | Where-Object { $_.Name -eq 'oh-my-opencode-slim.json' })[0]
    Assert-True -Condition ($pluginEntry.Merge -eq 'fixer.skills') -Message 'Phase 7 manifest lost the fixer.skills merge metadata.'
    Assert-True -Condition ($pluginEntry.BeforeSha256 -eq $successBeforeHash) -Message 'Phase 7 manifest recorded the wrong pre-merge hash.'
    Assert-True -Condition ($pluginEntry.AfterSha256 -eq (Get-TestHash -Path $successPlugin)) -Message 'Phase 7 manifest recorded the wrong post-merge hash.'

    $failureRoot = Join-Path $temporaryRoot 'failure'
    $failureBackupRoot = Join-Path $failureRoot 'backups'
    New-Item -ItemType Directory -Path $failureBackupRoot -Force -ErrorAction Stop | Out-Null
    $failurePlugin = Join-Path $failureRoot 'config\oh-my-opencode-slim.json'
    Write-TestJson -Path $failurePlugin -Value (New-TargetConfig)
    $failureBeforeHash = Get-TestHash -Path $failurePlugin
    $blockedParent = Join-Path $failureRoot 'blocked-parent'
    Set-Content -LiteralPath $blockedParent -Value 'not-a-directory' -Encoding Ascii

    $failureResult = Invoke-ApplyTest `
        -PluginTarget $failurePlugin `
        -OrchestratorPromptTarget (Join-Path $blockedParent 'orchestrator.md') `
        -FixerPromptTarget (Join-Path $failureRoot 'config\prompts\fixer.md') `
        -OraclePromptTarget (Join-Path $failureRoot 'config\prompts\oracle.md') `
        -DebuggingSkillTarget (Join-Path $failureRoot 'config\skills\systematic-debugging\SKILL.md') `
        -VerificationSkillTarget (Join-Path $failureRoot 'config\skills\verification-before-completion\SKILL.md') `
        -BackupRoot $failureBackupRoot
    Assert-True -Condition ($failureResult.ExitCode -ne 0) -Message 'Phase 7 failure injection unexpectedly passed.'
    Assert-True -Condition ($failureResult.Output.Contains('changed targets were restored')) -Message "Phase 7 failure injection did not report restoration.`n$($failureResult.Output)"
    Assert-True -Condition ((Get-TestHash -Path $failurePlugin) -eq $failureBeforeHash) -Message 'Phase 7 failure injection did not restore the original config bytes.'

    'Phase 7 isolated apply regression: PASS'
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
