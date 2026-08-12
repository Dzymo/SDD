[CmdletBinding()]
param(
    [string]$Root,
    [string]$OpenSpec,
    [int]$TimeoutSeconds = 30
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Expected,
        [string]$Label
    )

    if (-not $Content.Contains($Expected)) {
        throw "$Label is missing required source text: $Expected"
    }
}

function Resolve-OpenSpecExecutable {
    param([string]$Requested)

    $command = $null
    if (-not [string]::IsNullOrWhiteSpace($Requested)) {
        if (Test-Path -LiteralPath $Requested -PathType Leaf) {
            $command = Get-Item -LiteralPath $Requested
        }
        else {
            $command = Get-Command $Requested -ErrorAction Stop
        }
    }
    else {
        $command = Get-Command 'openspec' -ErrorAction Stop
    }

    $source = $null
    if ($null -ne $command.PSObject.Properties['FullName']) {
        $source = $command.FullName
    }
    if ([string]::IsNullOrWhiteSpace($source) -and $null -ne $command.PSObject.Properties['Source']) {
        $source = $command.Source
    }

    if ([System.IO.Path]::GetExtension($source) -ieq '.ps1') {
        $cmdSource = [System.IO.Path]::ChangeExtension($source, '.cmd')
        if (Test-Path -LiteralPath $cmdSource -PathType Leaf) {
            return $cmdSource
        }
    }

    return $source
}

function ConvertTo-ProcessArgument {
    param([string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    return '"' + $Value.Replace('"', '\"') + '"'
}

function Invoke-OpenSpec {
    param(
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    $display = 'openspec ' + ($Arguments -join ' ')
    [Console]::WriteLine("RUN: $display")

    $argumentText = (($Arguments | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join ' ')
    $extension = [System.IO.Path]::GetExtension($script:OpenSpecExecutable)
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo

    if ($extension -ieq '.cmd' -or $extension -ieq '.bat') {
        $startInfo.FileName = $env:ComSpec
        $startInfo.Arguments = '/d /s /c ""{0}" {1}"' -f $script:OpenSpecExecutable, $argumentText
    }
    elseif ($extension -ieq '.ps1') {
        $startInfo.FileName = (Get-Command 'powershell.exe' -ErrorAction Stop).Source
        $startInfo.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" {1}' -f $script:OpenSpecExecutable, $argumentText
    }
    else {
        $startInfo.FileName = $script:OpenSpecExecutable
        $startInfo.Arguments = $argumentText
    }

    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    foreach ($entry in $script:IsolatedEnvironment.GetEnumerator()) {
        $startInfo.EnvironmentVariables[$entry.Key] = $entry.Value
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    Assert-True -Condition $process.Start() -Message "Failed to start: $display"
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.Close()

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try { $process.Kill() } catch { }
        throw "Command timed out after $TimeoutSeconds seconds with closed stdin: $display"
    }

    $stdout = $stdoutTask.Result.Trim()
    $stderr = $stderrTask.Result.Trim()
    if ($process.ExitCode -ne 0) {
        throw "Command failed with exit code $($process.ExitCode): $display`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
    }

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        Stdout = $stdout
        Stderr = $stderr
    }
}

function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Get-TreeFingerprint {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return '<missing>'
    }

    $prefixLength = $Path.TrimEnd('\').Length + 1
    $entries = @(Get-ChildItem -LiteralPath $Path -Recurse -Force | Sort-Object FullName)
    $records = foreach ($entry in $entries) {
        $relative = $entry.FullName.Substring($prefixLength)
        if ($entry.PSIsContainer) {
            "D|$relative"
        }
        else {
            $hash = (Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256).Hash
            "F|$relative|$hash"
        }
    }

    return ($records -join "`n")
}

function Assert-MainSpecAppliedOnce {
    param([string]$SpecPath)

    Assert-True -Condition (Test-Path -LiteralPath $SpecPath -PathType Leaf) -Message "Expected main spec was not created: $SpecPath"
    $content = Get-Content -LiteralPath $SpecPath -Raw
    $requirementCount = [regex]::Matches($content, '(?m)^### Requirement: Status endpoint reports availability\s*$').Count
    Assert-True -Condition ($requirementCount -eq 1) -Message "Expected the status requirement exactly once in $SpecPath; found $requirementCount."
    Assert-True -Condition ($content -notmatch '(?m)^## ADDED Requirements\s*$') -Message "Main spec still contains a delta section: $SpecPath"
}

$commandRoot = Join-Path $Root 'templates\project\.opencode\commands'
$sourceExpectations = @{
    'opsx-explore.md' = @(
        'openspec list --json',
        'openspec list --store <id> --json',
        'openspec status --change "<name>" --store <id> --json'
    )
    'opsx-propose.md' = @(
        'openspec new change "<name>" --json',
        'openspec new change "<name>" --store <id> --json',
        'openspec status --change "<name>" --store <id> --json',
        'openspec instructions <artifact-id> --change "<name>" --store <id> --json',
        'openspec validate <name> --store <id> --strict --no-interactive'
    )
    'opsx-apply.md' = @(
        'openspec list --store <id> --json',
        'openspec status --change "<name>" --store <id> --json',
        'openspec instructions apply --change "<name>" --store <id> --json',
        'openspec validate <name> --store <id> --strict --no-interactive'
    )
    'opsx-sync.md' = @(
        'openspec list --store <id> --json',
        'openspec status --change "<name>" --store <id> --json',
        'openspec validate <name> --store <id> --strict --no-interactive',
        'SYNC-EXACTLY-ONCE'
    )
    'opsx-archive.md' = @(
        'openspec list --store <id> --json',
        'openspec status --change "<name>" --store <id> --json',
        'openspec instructions <tasks-artifact-id> --change "<name>" --store <id>',
        'openspec validate <name> --store <id> --strict --no-interactive',
        'openspec archive <change-name> --skip-specs --yes',
        'openspec archive <change-name> --yes',
        'openspec archive <change-name> --store <id> --skip-specs --yes',
        'openspec archive <change-name> --store <id> --yes'
    )
}

foreach ($fileName in $sourceExpectations.Keys) {
    $path = Join-Path $commandRoot $fileName
    Assert-True -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "Missing command template: $path"
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($expected in $sourceExpectations[$fileName]) {
        Assert-Contains -Content $content -Expected $expected -Label $fileName
    }
}

$archiveTemplate = Get-Content -LiteralPath (Join-Path $commandRoot 'opsx-archive.md') -Raw
$archiveCommandLines = @($archiveTemplate -split "`r?`n" | Where-Object { $_.TrimStart().StartsWith('openspec archive ') })
Assert-True -Condition ($archiveCommandLines.Count -eq 4) -Message "Expected exactly four explicit archive command branches; found $($archiveCommandLines.Count)."
foreach ($line in $archiveCommandLines) {
    Assert-True -Condition ($line -match '(?:^|\s)--yes(?:\s|$)') -Message "Interactive archive command is forbidden: $($line.Trim())"
}
[Console]::WriteLine('OpenSpec command template lifecycle assertions: PASS')

$fixtureRoot = Join-Path $Root 'fixtures\phase-6\valid-project'
Assert-True -Condition (Test-Path -LiteralPath $fixtureRoot -PathType Container) -Message "OpenSpec lifecycle fixture is missing: $fixtureRoot"

$tempParent = [System.IO.Path]::GetTempPath()
Assert-True -Condition (Test-Path -LiteralPath $tempParent -PathType Container) -Message "Temporary parent is missing: $tempParent"
$testRoot = Join-Path $tempParent "sdd-openspec-lifecycle-$([guid]::NewGuid().ToString('N'))"
$completed = $false
try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null

    $homeRoot = Join-Path $testRoot 'home'
    $appDataRoot = Join-Path $testRoot 'appdata'
    $localAppDataRoot = Join-Path $testRoot 'localappdata'
    $xdgConfigRoot = Join-Path $testRoot 'xdg-config'
    $xdgDataRoot = Join-Path $testRoot 'xdg-data'
    @($homeRoot, $appDataRoot, $localAppDataRoot, $xdgConfigRoot, $xdgDataRoot) | ForEach-Object {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }

    # OpenSpec 1.5.0 evidence:
    # - dist/core/global-config.js:getGlobalConfigDir uses XDG_CONFIG_HOME before APPDATA.
    # - dist/core/global-config.js:getGlobalDataDir uses XDG_DATA_HOME before LOCALAPPDATA.
    # - dist/core/store/foundation.js:getStoreRegistryPath stores registry.yaml under
    #   <global data>/openspec/stores. OPEN_SPEC_INTERACTIVE=0 is honored by
    #   dist/utils/interactive.js. These child-only values isolate the real user state.
    $script:IsolatedEnvironment = @{
        'HOME' = $homeRoot
        'USERPROFILE' = $homeRoot
        'APPDATA' = $appDataRoot
        'LOCALAPPDATA' = $localAppDataRoot
        'XDG_CONFIG_HOME' = $xdgConfigRoot
        'XDG_DATA_HOME' = $xdgDataRoot
        'OPENSPEC_TELEMETRY' = '0'
        'OPEN_SPEC_INTERACTIVE' = '0'
        'CI' = '1'
    }

    $script:OpenSpecExecutable = Resolve-OpenSpecExecutable -Requested $OpenSpec
    $versionResult = Invoke-OpenSpec -Arguments @('--version') -WorkingDirectory $testRoot
    Assert-True -Condition ($versionResult.Stdout.Trim() -eq '1.5.0') -Message "Expected OpenSpec 1.5.0, found '$($versionResult.Stdout)'."
    [Console]::WriteLine("OpenSpec executable: $script:OpenSpecExecutable (version 1.5.0)")
    [Console]::WriteLine('Isolation: XDG_CONFIG_HOME and XDG_DATA_HOME override Windows APPDATA and LOCALAPPDATA for OpenSpec 1.5.0.')

    $localUnsynced = Join-Path $testRoot 'local-unsynced'
    Copy-Item -LiteralPath $fixtureRoot -Destination $localUnsynced -Recurse
    Invoke-OpenSpec -Arguments @('list', '--json') -WorkingDirectory $localUnsynced | Out-Null
    Invoke-OpenSpec -Arguments @('status', '--change', 'add-status-endpoint', '--json') -WorkingDirectory $localUnsynced | Out-Null
    Invoke-OpenSpec -Arguments @('instructions', 'apply', '--change', 'add-status-endpoint', '--json') -WorkingDirectory $localUnsynced | Out-Null
    Invoke-OpenSpec -Arguments @('validate', 'add-status-endpoint', '--strict', '--no-interactive') -WorkingDirectory $localUnsynced | Out-Null
    Invoke-OpenSpec -Arguments @('archive', 'add-status-endpoint', '--yes') -WorkingDirectory $localUnsynced | Out-Null
    $unsyncedMainSpec = Join-Path $localUnsynced 'openspec\specs\status-endpoint\spec.md'
    Assert-MainSpecAppliedOnce -SpecPath $unsyncedMainSpec
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $localUnsynced 'openspec\changes\add-status-endpoint'))) -Message 'Unsynced local change remained active after archive.'
    [Console]::WriteLine('Unsynced local archive updated the main spec exactly once: PASS')

    $localSynced = Join-Path $testRoot 'local-synced'
    Copy-Item -LiteralPath $fixtureRoot -Destination $localSynced -Recurse
    $syncedMainSpec = Join-Path $localSynced 'openspec\specs\status-endpoint\spec.md'
    $syncedMainSpecParent = Split-Path -Parent $syncedMainSpec
    New-Item -ItemType Directory -Path $syncedMainSpecParent -Force | Out-Null
    Copy-Item -LiteralPath $unsyncedMainSpec -Destination $syncedMainSpec
    $syncedHashBefore = (Get-FileHash -LiteralPath $syncedMainSpec -Algorithm SHA256).Hash
    Invoke-OpenSpec -Arguments @('validate', 'add-status-endpoint', '--strict', '--no-interactive') -WorkingDirectory $localSynced | Out-Null
    Invoke-OpenSpec -Arguments @('archive', 'add-status-endpoint', '--skip-specs', '--yes') -WorkingDirectory $localSynced | Out-Null
    $syncedHashAfter = (Get-FileHash -LiteralPath $syncedMainSpec -Algorithm SHA256).Hash
    Assert-True -Condition ($syncedHashBefore -eq $syncedHashAfter) -Message 'Pre-synced local archive rewrote the main spec despite --skip-specs.'
    Assert-MainSpecAppliedOnce -SpecPath $syncedMainSpec
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $localSynced 'openspec\changes\add-status-endpoint'))) -Message 'Pre-synced local change remained active after archive.'
    [Console]::WriteLine('Pre-synced local archive succeeded without a second spec update: PASS')

    $storeId = 'phase-one-store'
    $storeRoot = Join-Path $testRoot 'selected-store'
    Invoke-OpenSpec -Arguments @('store', 'setup', $storeId, '--path', $storeRoot, '--no-init-git', '--json') -WorkingDirectory $testRoot | Out-Null
    $storeList = Invoke-OpenSpec -Arguments @('store', 'list', '--json') -WorkingDirectory $testRoot
    Assert-True -Condition ($storeList.Stdout -match 'phase-one-store') -Message 'Selected store was not present in the isolated registry.'

    $isolatedRegistry = Join-Path $xdgDataRoot 'openspec\stores\registry.yaml'
    Assert-True -Condition (Test-Path -LiteralPath $isolatedRegistry -PathType Leaf) -Message "Store registry was not written to isolated XDG_DATA_HOME: $isolatedRegistry"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $localAppDataRoot 'openspec\stores\registry.yaml'))) -Message 'OpenSpec ignored XDG_DATA_HOME and wrote the registry under LOCALAPPDATA.'

    $nearestLocal = Join-Path $testRoot 'nearest-local'
    Copy-Item -LiteralPath $fixtureRoot -Destination $nearestLocal -Recurse
    $nearestBefore = Get-TreeFingerprint -Path (Join-Path $nearestLocal 'openspec')

    Invoke-OpenSpec -Arguments @('list', '--store', $storeId, '--json') -WorkingDirectory $nearestLocal | Out-Null
    Invoke-OpenSpec -Arguments @('new', 'change', 'store-status-endpoint', '--store', $storeId, '--json') -WorkingDirectory $nearestLocal | Out-Null
    Invoke-OpenSpec -Arguments @('status', '--change', 'store-status-endpoint', '--store', $storeId, '--json') -WorkingDirectory $nearestLocal | Out-Null
    Invoke-OpenSpec -Arguments @('instructions', 'proposal', '--change', 'store-status-endpoint', '--store', $storeId, '--json') -WorkingDirectory $nearestLocal | Out-Null

    $storeChange = Join-Path $storeRoot 'openspec\changes\store-status-endpoint'
    $fixtureChange = Join-Path $fixtureRoot 'openspec\changes\add-status-endpoint'
    Copy-DirectoryContents -Source $fixtureChange -Destination $storeChange

    Invoke-OpenSpec -Arguments @('status', '--change', 'store-status-endpoint', '--store', $storeId, '--json') -WorkingDirectory $nearestLocal | Out-Null
    Invoke-OpenSpec -Arguments @('instructions', 'apply', '--change', 'store-status-endpoint', '--store', $storeId, '--json') -WorkingDirectory $nearestLocal | Out-Null
    Invoke-OpenSpec -Arguments @('validate', 'store-status-endpoint', '--store', $storeId, '--strict', '--no-interactive') -WorkingDirectory $nearestLocal | Out-Null
    Invoke-OpenSpec -Arguments @('archive', 'store-status-endpoint', '--store', $storeId, '--yes') -WorkingDirectory $nearestLocal | Out-Null

    $storeMainSpec = Join-Path $storeRoot 'openspec\specs\status-endpoint\spec.md'
    Assert-MainSpecAppliedOnce -SpecPath $storeMainSpec
    $storeSyncedHashBefore = (Get-FileHash -LiteralPath $storeMainSpec -Algorithm SHA256).Hash

    Invoke-OpenSpec -Arguments @('new', 'change', 'store-synced-status', '--store', $storeId, '--json') -WorkingDirectory $nearestLocal | Out-Null
    $storeSyncedChange = Join-Path $storeRoot 'openspec\changes\store-synced-status'
    Copy-DirectoryContents -Source $fixtureChange -Destination $storeSyncedChange
    Invoke-OpenSpec -Arguments @('validate', 'store-synced-status', '--store', $storeId, '--strict', '--no-interactive') -WorkingDirectory $nearestLocal | Out-Null
    Invoke-OpenSpec -Arguments @('archive', 'store-synced-status', '--store', $storeId, '--skip-specs', '--yes') -WorkingDirectory $nearestLocal | Out-Null

    $storeSyncedHashAfter = (Get-FileHash -LiteralPath $storeMainSpec -Algorithm SHA256).Hash
    Assert-True -Condition ($storeSyncedHashBefore -eq $storeSyncedHashAfter) -Message 'Pre-synced store archive rewrote the main spec despite --store and --skip-specs.'
    Assert-MainSpecAppliedOnce -SpecPath $storeMainSpec
    $nearestAfter = Get-TreeFingerprint -Path (Join-Path $nearestLocal 'openspec')
    Assert-True -Condition ($nearestBefore -eq $nearestAfter) -Message 'Store-backed lifecycle commands modified the nearest local openspec root.'
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $nearestLocal 'openspec\changes\store-status-endpoint'))) -Message 'Store-backed new change leaked into the nearest local openspec root.'
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $storeRoot 'openspec\changes\store-status-endpoint'))) -Message 'Store-backed change remained active after archive.'
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $storeRoot 'openspec\changes\store-synced-status'))) -Message 'Pre-synced store change remained active after archive.'
    [Console]::WriteLine('Store-backed lifecycle and both archive branches stayed in the selected isolated store: PASS')

    [Console]::WriteLine('OpenSpec lifecycle behavioral gate: PASS')
    $completed = $true
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $testRoot) {
        throw "Failed to clean isolated OpenSpec test root: $testRoot"
    }
    if ($completed) {
        [Console]::WriteLine('Isolated OpenSpec lifecycle test state cleanup: PASS')
    }
}
