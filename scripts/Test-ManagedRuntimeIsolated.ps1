[CmdletBinding()]
param(
    [string]$Root,
    [string]$Managed,
    [string]$PluginCacheSource,
    [switch]$KeepTemporaryRoot
)

Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}
if ([string]::IsNullOrWhiteSpace($Managed)) {
    $Managed = Join-Path $env:LOCALAPPDATA 'Programs\@openchamberelectron\resources\opencode-cli\opencode.exe'
}
if ([string]::IsNullOrWhiteSpace($PluginCacheSource)) {
    $PluginCacheSource = Join-Path $env:USERPROFILE '.cache\opencode\packages\oh-my-opencode-slim@2.2.8'
}

function Assert-True {
    param([bool]$Condition, [string]$Message)

    if (-not $Condition) {
        throw $Message
    }
}

function Get-DirectoryFingerprint {
    param(
        [string]$Path,
        [string[]]$ExcludedDirectoryNames = @()
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return 'ABSENT'
    }

    $root = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    $records = @()
    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push($root)
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($item in @(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop | Sort-Object FullName)) {
            $relativePath = $item.FullName.Substring($root.Length)
            if ($item.PSIsContainer) {
                if ($item.Name -in $ExcludedDirectoryNames) {
                    $records += "X|$relativePath"
                    continue
                }
                $records += "D|$relativePath"
                $pending.Push($item.FullName)
                continue
            }
            $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
            $records += "F|$relativePath|$($item.Length)|$hash"
        }
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString('X2') }) -join '')
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-KeyFileFingerprint {
    param([string[]]$Paths)

    $records = foreach ($path in $Paths) {
        Assert-True -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "Fingerprint input is missing: $path"
        "$path|$((Get-Item -LiteralPath $path -Force).Length)|$((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash)"
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString('X2') }) -join '')
    }
    finally {
        $sha256.Dispose()
    }
}

function Copy-ReviewedAsset {
    param([string]$Source, [string]$Destination)

    Assert-True -Condition (Test-Path -LiteralPath $Source -PathType Leaf) -Message "Reviewed runtime asset is missing: $Source"
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
}

function Set-ProcessEnvironment {
    param([hashtable]$Values)

    foreach ($name in $Values.Keys) {
        [System.Environment]::SetEnvironmentVariable($name, [string]$Values[$name], 'Process')
    }
}

function Invoke-SmokeStep {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    try {
        $output = & $Action 2>&1 | Out-String
        $script:SmokeResults += [pscustomobject]@{
            Name = $Name
            Result = 'PASS'
            Output = $output.Trim()
        }
        "PASS: $Name"
    }
    catch {
        $script:SmokeResults += [pscustomobject]@{
            Name = $Name
            Result = 'FAIL'
            Output = ($_ | Out-String).Trim()
        }
        "FAIL: $Name"
    }
}

Assert-True -Condition (Test-Path -LiteralPath $Managed -PathType Leaf) -Message "Managed OpenCode binary not found: $Managed"
Assert-True -Condition (Test-Path -LiteralPath $PluginCacheSource -PathType Container) -Message "Pinned slim package cache not found: $PluginCacheSource"
$pluginPackage = Join-Path $PluginCacheSource 'node_modules\oh-my-opencode-slim\package.json'
$pluginEntrypoint = Join-Path $PluginCacheSource 'node_modules\oh-my-opencode-slim\dist\index.js'
Assert-True -Condition (Test-Path -LiteralPath $pluginPackage -PathType Leaf) -Message "Pinned slim package manifest not found: $pluginPackage"
Assert-True -Condition (Test-Path -LiteralPath $pluginEntrypoint -PathType Leaf) -Message "Pinned slim plugin entrypoint not found: $pluginEntrypoint"
$pluginMetadata = Get-Content -LiteralPath $pluginPackage -Raw | ConvertFrom-Json -ErrorAction Stop
Assert-True -Condition ($pluginMetadata.version -eq '2.2.8') -Message "Expected slim package 2.2.8, found $($pluginMetadata.version)."

$realUserProfile = $env:USERPROFILE
$globalConfigRoot = Join-Path $realUserProfile '.config\opencode'
$globalConfigBefore = Get-DirectoryFingerprint -Path $globalConfigRoot -ExcludedDirectoryNames @('node_modules')
$pluginCacheBefore = Get-KeyFileFingerprint -Paths @($pluginPackage, $pluginEntrypoint)
$temporaryParent = [System.IO.Path]::GetTempPath()
Assert-True -Condition (Test-Path -LiteralPath $temporaryParent -PathType Container) -Message "Temporary parent is missing: $temporaryParent"
$temporaryBase = Join-Path $temporaryParent 'opencode'
if (-not (Test-Path -LiteralPath $temporaryBase -PathType Container)) {
    New-Item -ItemType Directory -Path $temporaryBase -ErrorAction Stop | Out-Null
}
$temporaryRoot = Join-Path $temporaryBase "sdd-managed-runtime-isolated-$([guid]::NewGuid().ToString('N'))"
$savedEnvironment = @{}
$smokeFailure = $null
$SmokeResults = @()
$pluginCacheTarget = $null

try {
    $homeDir = Join-Path $temporaryRoot 'home'
    $configDir = Join-Path $temporaryRoot 'config'
    $cacheDir = Join-Path $temporaryRoot 'cache'
    $dataDir = Join-Path $temporaryRoot 'data'
    $stateDir = Join-Path $temporaryRoot 'state'
    $workspaceDir = Join-Path $temporaryRoot 'workspace'
    $localAppData = Join-Path $temporaryRoot 'AppData\Local'
    $roamingAppData = Join-Path $temporaryRoot 'AppData\Roaming'
    foreach ($directory in @($homeDir, $configDir, $cacheDir, $dataDir, $stateDir, $workspaceDir, $localAppData, $roamingAppData)) {
        New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop | Out-Null
    }

    $pluginCacheTarget = Join-Path $cacheDir 'opencode\packages\oh-my-opencode-slim@2.2.8'
    New-Item -ItemType Directory -Path (Split-Path -Parent $pluginCacheTarget) -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Junction -Path $pluginCacheTarget -Target $PluginCacheSource -ErrorAction Stop | Out-Null

    $opencodeConfig = [ordered]@{
        '$schema' = 'https://opencode.ai/config.json'
        autoupdate = $false
        share = 'disabled'
        snapshot = $false
        plugin = @('oh-my-opencode-slim@2.2.8')
        mcp = [ordered]@{
            context7 = [ordered]@{
                type = 'remote'
                url = 'https://mcp.context7.com/mcp/oauth'
                enabled = $true
            }
            codegraph = [ordered]@{
                type = 'local'
                command = @('codegraph', 'serve', '--mcp')
                enabled = $true
            }
        }
        references = [ordered]@{
            codegraph = [ordered]@{
                path = 'D:\Projects\Docs\codegraph'
                description = 'Local CodeGraph source for exact implementation evidence.'
                hidden = $true
            }
        }
    }
    $opencodeConfigPath = Join-Path $configDir 'opencode.jsonc'
    $opencodeConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $opencodeConfigPath -Encoding Ascii

    $pluginTarget = Join-Path $configDir 'oh-my-opencode-slim.json'
    Copy-ReviewedAsset -Source (Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json') -Destination $pluginTarget

    $promptTargets = @{
        orchestrator = Join-Path $configDir 'oh-my-opencode-slim\sdd-personal\orchestrator.md'
        fixer = Join-Path $configDir 'oh-my-opencode-slim\sdd-personal\fixer.md'
        oracle = Join-Path $configDir 'oh-my-opencode-slim\sdd-personal\oracle.md'
        designer = Join-Path $configDir 'oh-my-opencode-slim\sdd-personal\designer.md'
        observer = Join-Path $configDir 'oh-my-opencode-slim\sdd-personal\observer.md'
    }
    foreach ($agent in $promptTargets.Keys) {
        Copy-ReviewedAsset -Source (Join-Path $Root "prompts\oh-my-opencode-slim\sdd-personal\$agent.md") -Destination $promptTargets[$agent]
    }

    $skillTargets = @{
        debugging = Join-Path $configDir 'skills\systematic-debugging\SKILL.md'
        verification = Join-Path $configDir 'skills\verification-before-completion\SKILL.md'
        ui = Join-Path $configDir 'skills\ui-quality\SKILL.md'
        release = Join-Path $configDir 'skills\package-and-release\SKILL.md'
    }
    Copy-ReviewedAsset -Source (Join-Path $Root 'skills\systematic-debugging\SKILL.md') -Destination $skillTargets.debugging
    Copy-ReviewedAsset -Source (Join-Path $Root 'skills\verification-before-completion\SKILL.md') -Destination $skillTargets.verification
    Copy-ReviewedAsset -Source (Join-Path $Root 'skills\ui-quality\SKILL.md') -Destination $skillTargets.ui
    Copy-ReviewedAsset -Source (Join-Path $Root 'skills\package-and-release\SKILL.md') -Destination $skillTargets.release

    foreach ($entry in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'OPENCODE_*' })) {
        $savedEnvironment[$entry.Name] = $entry.Value
        Remove-Item -LiteralPath "Env:\$($entry.Name)"
    }
    foreach ($name in @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_DATA_HOME', 'XDG_STATE_HOME')) {
        if (-not $savedEnvironment.ContainsKey($name)) {
            $savedEnvironment[$name] = [System.Environment]::GetEnvironmentVariable($name, 'Process')
        }
    }

    Set-ProcessEnvironment -Values @{
        HOME = $homeDir
        USERPROFILE = $homeDir
        APPDATA = $roamingAppData
        LOCALAPPDATA = $localAppData
        XDG_CONFIG_HOME = $configDir
        XDG_CACHE_HOME = $cacheDir
        XDG_DATA_HOME = $dataDir
        XDG_STATE_HOME = $stateDir
        OPENCODE_TEST_HOME = $homeDir
        OPENCODE_CONFIG_DIR = $configDir
        OPENCODE_DISABLE_PROJECT_CONFIG = '1'
        OPENCODE_DISABLE_AUTOUPDATE = 'true'
        OPENCODE_DISABLE_AUTOCOMPACT = 'true'
        OPENCODE_DISABLE_MODELS_FETCH = 'true'
        OPENCODE_DISABLE_DEFAULT_PLUGINS = 'true'
        OPENCODE_AUTH_CONTENT = '{}'
    }

    Push-Location -LiteralPath $workspaceDir
    try {
        Invoke-SmokeStep -Name 'Managed path isolation' -Action {
            $paths = & $Managed debug paths 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) {
                throw "Managed debug paths failed.`n$paths"
            }
            Assert-True -Condition ($paths.Contains($configDir)) -Message "Managed config path is not isolated.`n$paths"
            Assert-True -Condition ($paths.Contains((Join-Path $cacheDir 'opencode'))) -Message "Managed cache path is not isolated.`n$paths"
            Assert-True -Condition (-not $paths.Contains($globalConfigRoot)) -Message "Managed paths still reference the real global config.`n$paths"
        }

        Invoke-SmokeStep -Name 'Phase 4 agent layer runtime' -Action {
            & (Join-Path $Root 'scripts\Test-AgentLayerRuntime.ps1') -Managed $Managed
        }
        Invoke-SmokeStep -Name 'Phase 7 execution runtime' -Action {
            & (Join-Path $Root 'scripts\Test-ExecutionVerificationRuntime.ps1') `
                -Root $Root `
                -Managed $Managed `
                -PluginTarget $pluginTarget `
                -OrchestratorPromptTarget $promptTargets.orchestrator `
                -FixerPromptTarget $promptTargets.fixer `
                -OraclePromptTarget $promptTargets.oracle `
                -DebuggingSkillTarget $skillTargets.debugging `
                -VerificationSkillTarget $skillTargets.verification
        }
        Invoke-SmokeStep -Name 'Phase 8 operating guide runtime' -Action {
            & (Join-Path $Root 'scripts\Test-OpenChamberOperatingGuideRuntime.ps1') `
                -Root $Root `
                -Managed $Managed `
                -PromptPath $promptTargets.orchestrator
        }
        Invoke-SmokeStep -Name 'Phase 9 UI quality runtime' -Action {
            & (Join-Path $Root 'scripts\Test-UIQualityLayerRuntime.ps1') `
                -Root $Root `
                -Managed $Managed `
                -PluginTarget $pluginTarget `
                -DesignerPromptTarget $promptTargets.designer `
                -ObserverPromptTarget $promptTargets.observer `
                -SkillTarget $skillTargets.ui
        }
        Invoke-SmokeStep -Name 'Phase 10 packaging runtime' -Action {
            & (Join-Path $Root 'scripts\Test-PackagingReleaseRuntime.ps1') `
                -Root $Root `
                -Managed $Managed `
                -OrchestratorPromptTarget $promptTargets.orchestrator `
                -SkillTarget $skillTargets.release
        }
    }
    finally {
        Pop-Location
    }

    $failedSteps = @($SmokeResults | Where-Object { $_.Result -eq 'FAIL' })
    if ($failedSteps.Count -gt 0) {
        $details = $failedSteps | ForEach-Object { "$($_.Name): $($_.Output)" }
        throw "Isolated managed-runtime smoke had $($failedSteps.Count) failed step(s).`n$($details -join "`n`n")"
    }
}
catch {
    $smokeFailure = $_
}
finally {
    foreach ($entry in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'OPENCODE_*' })) {
        Remove-Item -LiteralPath "Env:\$($entry.Name)"
    }
    foreach ($name in $savedEnvironment.Keys) {
        [System.Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
    if (-not $KeepTemporaryRoot -and -not [string]::IsNullOrWhiteSpace($pluginCacheTarget) -and (Test-Path -LiteralPath $pluginCacheTarget)) {
        $cacheLink = Get-Item -LiteralPath $pluginCacheTarget -Force -ErrorAction SilentlyContinue
        if ($null -ne $cacheLink -and ($cacheLink.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            [System.IO.Directory]::Delete($pluginCacheTarget)
        }
    }
    if (-not $KeepTemporaryRoot -and (Test-Path -LiteralPath $temporaryRoot)) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$globalConfigAfter = Get-DirectoryFingerprint -Path $globalConfigRoot -ExcludedDirectoryNames @('node_modules')
$pluginCacheAfter = Get-KeyFileFingerprint -Paths @($pluginPackage, $pluginEntrypoint)
if ($globalConfigAfter -ne $globalConfigBefore) {
    throw "Global OpenCode config changed during the isolated smoke: $globalConfigRoot"
}
if ($pluginCacheAfter -ne $pluginCacheBefore) {
    throw "Pinned plugin package manifest or entrypoint changed during the isolated smoke: $PluginCacheSource"
}
if ($null -ne $smokeFailure) {
    if ($KeepTemporaryRoot) {
        "Isolated managed-runtime temporary root retained: $temporaryRoot"
    }
    throw $smokeFailure
}

"Managed OpenCode version: $(& $Managed --version)"
"Slim package version: $($pluginMetadata.version)"
'Global config fingerprint unchanged: PASS'
'Pinned plugin package key-file fingerprint unchanged: PASS'
'Isolated managed-runtime smoke: PASS'
