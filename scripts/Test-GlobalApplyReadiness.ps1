[CmdletBinding()]
param(
    [string]$Root,
    [string]$OpenCodeRoot = 'C:\Users\quang\.config\opencode',
    [string]$PhaseFivePackagePath = 'C:\Users\quang\.cache\opencode\packages\oh-my-opencode-slim@2.2.8\node_modules\oh-my-opencode-slim\dist\index.js',
    [string]$PhaseFiveExpectedHash = '6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A',
    [string[]]$SimulatedProcessNames,
    [switch]$SimulatedDirty,
    [object[]]$AdditionalTargets = @(),
    [string]$OutputPath,
    [switch]$Text
)

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Get-NormalizedJsonValue {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }
    if ($Value -is [pscustomobject] -or $Value -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($name in ($Value.PSObject.Properties | Sort-Object Name)) {
            $ordered[$name.Name] = Get-NormalizedJsonValue -Value $name.Value
        }
        return $ordered
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += , (Get-NormalizedJsonValue -Value $item)
        }
        return , $items
    }
    return $Value
}

function ConvertTo-NormalizedJsonText {
    param($Value)

    $normalized = Get-NormalizedJsonValue -Value $Value
    return (ConvertTo-Json -InputObject $normalized -Depth 100 -Compress)
}

function Get-TargetValue {
    param(
        [object]$Object,
        [string]$Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        return $Object
    }

    $value = $Object
    foreach ($segment in ($Path -split '\.' | Where-Object { $_ })) {
        if ($null -eq $value) { break }
        $value = $value.$segment
    }
    return $value
}

function Compare-SemanticFields {
    param(
        [string]$TargetFile,
        [object[]]$MergeSpec,
        [string]$Root
    )

    if (-not (Test-Path -LiteralPath $TargetFile -PathType Leaf)) {
        return @{ Equal = $false; Reason = 'missing-target' }
    }

    try {
        $targetJson = Get-Content -LiteralPath $TargetFile -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return @{ Equal = $false; Reason = "unreadable-target: $($_.Exception.Message)" }
    }

    foreach ($entry in $MergeSpec) {
        $sourceFile = if ([System.IO.Path]::IsPathRooted($entry.SourceFile)) {
            $entry.SourceFile
        }
        else {
            Join-Path $Root $entry.SourceFile
        }
        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
            return @{ Equal = $false; Reason = "missing-source:$($entry.SourceFile)" }
        }

        try {
            $sourceJson = Get-Content -LiteralPath $sourceFile -Raw | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            return @{ Equal = $false; Reason = "unreadable-source:$($entry.SourceFile):$($_.Exception.Message)" }
        }

        $sourceValue = Get-TargetValue -Object $sourceJson -Path $entry.SourceFieldPath
        $targetValue = Get-TargetValue -Object $targetJson -Path $entry.TargetFieldPath

        $sourceText = ConvertTo-NormalizedJsonText -Value $sourceValue
        $targetText = ConvertTo-NormalizedJsonText -Value $targetValue

        if ($sourceText -ne $targetText) {
            return @{ Equal = $false; Reason = "field-mismatch:$($entry.TargetFieldPath)" }
        }
    }

    return @{ Equal = $true }
}

function Compare-SemanticComplete {
    param(
        [string]$TargetFile,
        [string]$SourceFile
    )

    if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {
        return @{ Equal = $false; Reason = "missing-source:$SourceFile" }
    }

    if (-not (Test-Path -LiteralPath $TargetFile -PathType Leaf)) {
        return @{ Equal = $false; Reason = 'missing-target' }
    }

    try {
        $sourceJson = Get-Content -LiteralPath $SourceFile -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return @{ Equal = $false; Reason = "unreadable-source:$SourceFile`:$($_.Exception.Message)" }
    }

    try {
        $targetJson = Get-Content -LiteralPath $TargetFile -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return @{ Equal = $false; Reason = "unreadable-target:$($_.Exception.Message)" }
    }

    $sourceText = ConvertTo-NormalizedJsonText -Value $sourceJson
    $targetText = ConvertTo-NormalizedJsonText -Value $targetJson

    if ($sourceText -eq $targetText) {
        return @{ Equal = $true }
    }

    $sourceKeys = @($sourceJson.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
    $targetKeys = @($targetJson.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
    $allKeys = @($sourceKeys + $targetKeys | Sort-Object -Unique)
    $differingKeys = @()
    foreach ($key in $allKeys) {
        $sourceHas = $sourceJson.PSObject.Properties.Name -contains $key
        $targetHas = $targetJson.PSObject.Properties.Name -contains $key
        if (-not $sourceHas -or -not $targetHas) {
            $differingKeys += "$key (missing in $(if ($sourceHas) {'target'} else {'source'}))"
            continue
        }
        $sourceText = ConvertTo-NormalizedJsonText -Value $sourceJson.$key
        $targetText = ConvertTo-NormalizedJsonText -Value $targetJson.$key
        if ($sourceText -ne $targetText) {
            $differingKeys += $key
        }
    }

    return @{
        Equal = $false
        Reason = "semantic-complete-mismatch: keys differ [$(-join $differingKeys)]"
        DifferingKeys = $differingKeys
    }
}

function Get-TargetHash {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 'ABSENT'
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-FrameworkOwnedTargets {
    return @(
        @{
            Name = 'opencode.jsonc'
            Phase = '3'
            Owner = 'Phase 3 research'
            RelativeTargetPath = 'opencode.jsonc'
            ComparisonType = 'semantic-merge-spec'
            ApplyScripts = @('Apply-ResearchMcp.ps1')
            Verifiers = @('Test-ResearchRuntime.ps1', 'Test-AgentLayerRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @(
                @{ SourceFile = 'config\opencode\research-mcp.json'; SourceFieldPath = 'mcp.context7'; TargetFieldPath = 'mcp.context7' },
                @{ SourceFile = 'config\opencode\research-mcp.json'; SourceFieldPath = 'mcp.codegraph'; TargetFieldPath = 'mcp.codegraph' },
                @{ SourceFile = 'config\opencode\research-references.json'; SourceFieldPath = 'references.codegraph'; TargetFieldPath = 'references.codegraph' },
                @{ SourceFile = 'config\opencode\agent-layer.plugin.json'; SourceFieldPath = 'plugin'; TargetFieldPath = 'plugin'; UnsupportedIfDrift = $true }
            )
        },
        @{
            Name = 'oh-my-opencode-slim.json'
            Phase = '3, 7, 9'
            Owner = 'Phase 3 research/Phase 7 execution/Phase 9 UI quality (merged)'
            RelativeTargetPath = 'oh-my-opencode-slim.json'
            ComparisonType = 'semantic-complete'
            ApplyScripts = @('Apply-ResearchMcp.ps1', 'Apply-ExecutionVerification.ps1', 'Apply-UIQualityLayer.ps1')
            Verifiers = @('Test-ResearchRuntime.ps1', 'Test-ExecutionVerificationRuntime.ps1', 'Test-UIQualityLayerRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = 'config\oh-my-opencode-slim\sdd-personal.json'
            MergeSpec = @()
        },
        @{
            Name = 'orchestrator.md'
            Phase = '7, 8, 10'
            Owner = 'Phase 7 execution + Phase 8 OpenChamber + Phase 10 packaging (shared)'
            RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\orchestrator.md'
            RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ExecutionVerification.ps1', 'Apply-OpenChamberOperatingGuide.ps1', 'Apply-PackagingRelease.ps1')
            Verifiers = @('Test-ExecutionVerificationRuntime.ps1', 'Test-OpenChamberOperatingGuideRuntime.ps1', 'Test-PackagingReleaseRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'explorer.md'
            Phase = '3'
            Owner = 'Phase 3 research'
            RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\explorer.md'
            RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\explorer.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ResearchMcp.ps1')
            Verifiers = @('Test-AgentLayerRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'librarian.md'
            Phase = '3'
            Owner = 'Phase 3 research'
            RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\librarian.md'
            RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\librarian.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ResearchMcp.ps1')
            Verifiers = @('Test-AgentLayerRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'fixer.md'
            Phase = '7'
            Owner = 'Phase 7 execution'
            RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\fixer.md'
            RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\fixer.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ExecutionVerification.ps1')
            Verifiers = @('Test-ExecutionVerificationRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'oracle.md'
            Phase = '7'
            Owner = 'Phase 7 execution'
            RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\oracle.md'
            RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\oracle.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ExecutionVerification.ps1')
            Verifiers = @('Test-ExecutionVerificationRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'designer.md'
            Phase = '9'
            Owner = 'Phase 9 UI quality'
            RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\designer.md'
            RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\designer.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-UIQualityLayer.ps1')
            Verifiers = @('Test-UIQualityLayerRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'observer.md'
            Phase = '9'
            Owner = 'Phase 9 UI quality'
            RelativeTargetPath = 'oh-my-opencode-slim\sdd-personal\observer.md'
            RelativeSourcePath = 'prompts\oh-my-opencode-slim\sdd-personal\observer.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-UIQualityLayer.ps1')
            Verifiers = @('Test-UIQualityLayerRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'source-first-research.SKILL.md'
            Phase = '3'
            Owner = 'Phase 3 research'
            RelativeTargetPath = 'skills\source-first-research\SKILL.md'
            RelativeSourcePath = 'skills\source-first-research\SKILL.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ResearchMcp.ps1')
            Verifiers = @('Test-ResearchRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'systematic-debugging.SKILL.md'
            Phase = '7'
            Owner = 'Phase 7 execution'
            RelativeTargetPath = 'skills\systematic-debugging\SKILL.md'
            RelativeSourcePath = 'skills\systematic-debugging\SKILL.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ExecutionVerification.ps1')
            Verifiers = @('Test-ExecutionVerificationRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'verification-before-completion.SKILL.md'
            Phase = '7'
            Owner = 'Phase 7 execution'
            RelativeTargetPath = 'skills\verification-before-completion\SKILL.md'
            RelativeSourcePath = 'skills\verification-before-completion\SKILL.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-ExecutionVerification.ps1')
            Verifiers = @('Test-ExecutionVerificationRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'ui-quality.SKILL.md'
            Phase = '9'
            Owner = 'Phase 9 UI quality'
            RelativeTargetPath = 'skills\ui-quality\SKILL.md'
            RelativeSourcePath = 'skills\ui-quality\SKILL.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-UIQualityLayer.ps1')
            Verifiers = @('Test-UIQualityLayerRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        },
        @{
            Name = 'package-and-release.SKILL.md'
            Phase = '10'
            Owner = 'Phase 10 packaging'
            RelativeTargetPath = 'skills\package-and-release\SKILL.md'
            RelativeSourcePath = 'skills\package-and-release\SKILL.md'
            ComparisonType = 'raw'
            ApplyScripts = @('Apply-PackagingRelease.ps1')
            Verifiers = @('Test-PackagingReleaseRuntime.ps1')
            RollbackSupported = $true
            ManagedSourceKey = $null
            MergeSpec = @()
        }
    )
}

function Resolve-TargetPaths {
    param(
        [hashtable]$Metadata,
        [string]$OpenCodeRoot,
        [string]$Root
    )

    $targetPath = if ([System.IO.Path]::IsPathRooted($Metadata.RelativeTargetPath)) {
        $Metadata.RelativeTargetPath
    }
    else {
        Join-Path $OpenCodeRoot $Metadata.RelativeTargetPath
    }

    $sourcePath = $null
    if ($Metadata.ContainsKey('RelativeSourcePath') -and -not [string]::IsNullOrWhiteSpace($Metadata.RelativeSourcePath)) {
        $sourcePath = if ([System.IO.Path]::IsPathRooted($Metadata.RelativeSourcePath)) {
            $Metadata.RelativeSourcePath
        }
        else {
            Join-Path $Root $Metadata.RelativeSourcePath
        }
    }

    $completeSourcePath = $null
    if ($Metadata.ContainsKey('ManagedSourceKey') -and -not [string]::IsNullOrWhiteSpace($Metadata.ManagedSourceKey)) {
        $completeSourcePath = Join-Path $Root $Metadata.ManagedSourceKey
    }

    $mergeSourcePaths = @()
    if ($Metadata.ComparisonType -eq 'semantic-merge-spec') {
        foreach ($entry in $Metadata.MergeSpec) {
            $mergeSourcePaths += if ([System.IO.Path]::IsPathRooted($entry.SourceFile)) {
                $entry.SourceFile
            }
            else {
                Join-Path $Root $entry.SourceFile
            }
        }
    }

    return @{
        TargetPath = $targetPath
        SourcePath = $sourcePath
        CompleteSourcePath = $completeSourcePath
        MergeSourcePaths = $mergeSourcePaths
    }
}

function Compare-TargetDrift {
    param(
        [hashtable]$Metadata,
        [hashtable]$Paths,
        [string]$Root
    )

    $targetPath = $Paths.TargetPath
    $targetExists = Test-Path -LiteralPath $targetPath -PathType Leaf

    $sourceHash = 'MISSING_SOURCE'
    $sourceExists = $false
    if ($Metadata.ComparisonType -eq 'semantic-complete') {
        if ($Paths.CompleteSourcePath -and (Test-Path -LiteralPath $Paths.CompleteSourcePath -PathType Leaf)) {
            $sourceExists = $true
            $sourceHash = Get-TargetHash -Path $Paths.CompleteSourcePath
        }
    }
    elseif ($Metadata.ComparisonType -eq 'semantic-merge-spec') {
        $allSourcesPresent = $true
        $hashes = @()
        foreach ($p in $Paths.MergeSourcePaths) {
            if (Test-Path -LiteralPath $p -PathType Leaf) {
                $hashes += Get-TargetHash -Path $p
            }
            else {
                $allSourcesPresent = $false
                break
            }
        }
        if ($allSourcesPresent) {
            $sourceExists = $true
            $sourceHash = ($hashes -join '|')
        }
    }
    else {
        if ($Paths.SourcePath -and (Test-Path -LiteralPath $Paths.SourcePath -PathType Leaf)) {
            $sourceExists = $true
            $sourceHash = Get-TargetHash -Path $Paths.SourcePath
        }
    }

    $targetHash = Get-TargetHash -Path $targetPath

    if (-not $sourceExists) {
        return @{
            SourceHash = 'MISSING_SOURCE'
            TargetHash = $targetHash
            Match = 'MISSING_SOURCE'
            Support = 'UNSUPPORTED'
            Reason = 'Framework source is missing for this target.'
            DifferingKeys = @()
        }
    }

    if (-not $targetExists) {
        return @{
            SourceHash = $sourceHash
            TargetHash = 'ABSENT'
            Match = 'ABSENT'
            Support = 'UNSUPPORTED'
            Reason = 'Required framework-owned target is absent.'
            DifferingKeys = @()
        }
    }

    $comparison = $null
    switch ($Metadata.ComparisonType) {
        'semantic-merge-spec' {
            $comparison = Compare-SemanticFields -TargetFile $targetPath -MergeSpec $Metadata.MergeSpec -Root $Root
        }
        'semantic-complete' {
            $comparison = Compare-SemanticComplete -TargetFile $targetPath -SourceFile $Paths.CompleteSourcePath
        }
        default {
            if ($sourceHash -eq $targetHash) {
                $comparison = @{ Equal = $true }
            }
            else {
                $comparison = @{ Equal = $false; Reason = 'hash-mismatch' }
            }
        }
    }

    if ($comparison.Equal) {
        return @{
            SourceHash = $sourceHash
            TargetHash = $targetHash
            Match = 'MATCH'
            Support = 'SUPPORTED'
            Reason = 'Source and target are equal.'
            DifferingKeys = @()
        }
    }

    $driftReason = "Drift detected: $($comparison.Reason)"
    $support = 'SUPPORTED'
    if ($Metadata.ApplyScripts.Count -eq 0) {
        $support = 'UNSUPPORTED'
    }
    elseif ($Metadata.ComparisonType -eq 'semantic-merge-spec') {
        $driftedFields = @()
        foreach ($entry in $Metadata.MergeSpec) {
            $entryPath = if ([System.IO.Path]::IsPathRooted($entry.SourceFile)) {
                $entry.SourceFile
            }
            else {
                Join-Path $Root $entry.SourceFile
            }
            try {
                $sourceJson = Get-Content -LiteralPath $entryPath -Raw | ConvertFrom-Json -ErrorAction Stop
                $sourceValue = Get-TargetValue -Object $sourceJson -Path $entry.SourceFieldPath
                $targetJson = Get-Content -LiteralPath $targetPath -Raw | ConvertFrom-Json -ErrorAction Stop
                $targetValue = Get-TargetValue -Object $targetJson -Path $entry.TargetFieldPath
                $sourceText = ConvertTo-NormalizedJsonText -Value $sourceValue
                $targetText = ConvertTo-NormalizedJsonText -Value $targetValue
                if ($sourceText -ne $targetText) {
                    $driftedFields += $entry.TargetFieldPath
                    if ($entry.ContainsKey('UnsupportedIfDrift') -and $entry.UnsupportedIfDrift) {
                        $support = 'UNSUPPORTED'
                    }
                }
            }
            catch {
                $driftedFields += "$($entry.TargetFieldPath) (unreadable)"
                if ($entry.ContainsKey('UnsupportedIfDrift') -and $entry.UnsupportedIfDrift) {
                    $support = 'UNSUPPORTED'
                }
            }
        }
        $driftReason = "Drifted fields: [$(-join $driftedFields)]. $driftReason"
    }

    return @{
        SourceHash = $sourceHash
        TargetHash = $targetHash
        Match = 'DRIFT'
        Support = $support
        Reason = $driftReason
        DifferingKeys = if ($comparison.ContainsKey('DifferingKeys')) { $comparison.DifferingKeys } else { @() }
    }
}

function Get-CandidateState {
    param(
        [string]$Root,
        [bool]$SimulatedDirty
    )

    $gitDir = Join-Path $Root '.git'
    if (-not (Test-Path -LiteralPath $gitDir -PathType Container)) {
        if ($SimulatedDirty) {
            return @{
                Sha = $null
                Branch = $null
                Clean = $false
                StatusShort = 'simulated-dirty (no git repository in $Root)'
                Root = $Root
            }
        }
        return @{
            Sha = $null
            Branch = $null
            Clean = $true
            StatusShort = '(no git repository in $Root)'
            Root = $Root
        }
    }

    $sha = $null
    $branch = $null
    $statusShort = ''
    try {
        $sha = (& git -C $Root rev-parse HEAD 2>$null).Trim()
    }
    catch {
        $sha = $null
    }
    try {
        $branch = (& git -C $Root rev-parse --abbrev-ref HEAD 2>$null).Trim()
    }
    catch {
        $branch = $null
    }
    try {
        $statusShort = (& git -C $Root status --short 2>$null) -join "`n"
    }
    catch {
        $statusShort = ''
    }

    $clean = [string]::IsNullOrWhiteSpace($statusShort) -and -not $SimulatedDirty

    return @{
        Sha = $sha
        Branch = $branch
        Clean = $clean
        StatusShort = $statusShort
        Root = $Root
    }
}

function Get-ProcessState {
    param([string[]]$SimulatedProcessNames)

    $blockedNames = @('openchamber', 'cpa', 'opencode')
    $running = @()

    if ($null -ne $SimulatedProcessNames) {
        foreach ($name in $SimulatedProcessNames) {
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            $running += [pscustomobject]@{ ProcessName = $name; Id = 4242 }
        }
    }
    else {
        $allProcesses = @(Get-Process -ErrorAction SilentlyContinue)
        foreach ($process in $allProcesses) {
            foreach ($blocked in $blockedNames) {
                if ($process.ProcessName -ieq $blocked) {
                    $running += [pscustomobject]@{ ProcessName = $process.ProcessName; Id = $process.Id }
                    break
                }
            }
        }
    }

    return @{
        Running = $running
        Blocked = $running.Count -gt 0
    }
}

function Get-PhaseFivePackageState {
    param(
        [string]$PackagePath,
        [string]$ExpectedHash
    )

    $exists = Test-Path -LiteralPath $PackagePath -PathType Leaf
    $hash = 'ABSENT'
    if ($exists) {
        $hash = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash
    }

    $match = 'ABSENT'
    if (-not $exists) {
        $match = 'ABSENT'
    }
    elseif ([string]::IsNullOrWhiteSpace($ExpectedHash)) {
        $match = 'UNKNOWN'
    }
    elseif ($hash -eq $ExpectedHash) {
        $match = 'MATCH'
    }
    else {
        $match = 'DRIFT'
    }

    return @{
        Path = $PackagePath
        Exists = $exists
        Hash = $hash
        ExpectedHash = $ExpectedHash
        Match = $match
    }
}

function Get-Verdict {
    param(
        [hashtable]$Candidate,
        [hashtable]$ProcessState,
        [hashtable]$PhaseFive,
        [object[]]$TargetResults
    )

    $reasons = @()

    if (-not $Candidate.Clean) {
        $reasons += "Dirty candidate worktree. Status: $($Candidate.StatusShort)"
    }

    if ($PhaseFive.Match -eq 'DRIFT') {
        $reasons += "Phase 5 package hash drifted from expected. Found: $($PhaseFive.Hash). Expected: $($PhaseFive.ExpectedHash)"
    }
    elseif ($PhaseFive.Match -eq 'ABSENT') {
        $reasons += "Phase 5 package is absent at $($PhaseFive.Path)."
    }

    $missingSource = @($TargetResults | Where-Object { $_.Match -eq 'MISSING_SOURCE' })
    foreach ($entry in $missingSource) {
        $reasons += "Missing or invalid framework source for target '$($entry.Name)': $($entry.Reason)"
    }

    $unsupported = @($TargetResults | Where-Object { $_.Support -eq 'UNSUPPORTED' })
    foreach ($entry in $unsupported) {
        $reasons += "Unsupported drift for target '$($entry.Name)': $($entry.Reason)"
    }

    $absent = @($TargetResults | Where-Object { $_.Match -eq 'ABSENT' })
    foreach ($entry in $absent) {
        $reasons += "Required target '$($entry.Name)' is absent at $($entry.TargetPath); no apply is permitted during this rollout."
    }

    if ($reasons.Count -gt 0) {
        return @{
            Value = 'BLOCKED'
            Reasons = $reasons
            ApplyPreconditionSatisfied = $false
        }
    }

    $driftOrAbsent = @($TargetResults | Where-Object { $_.Match -in @('DRIFT', 'ABSENT') })
    $allMatch = $driftOrAbsent.Count -eq 0

    if ($allMatch) {
        return @{
            Value = 'NO_APPLY_REQUIRED'
            Reasons = @()
            ApplyPreconditionSatisfied = -not $ProcessState.Blocked
        }
    }

    $supportedDrift = @($driftOrAbsent | Where-Object { $_.Support -eq 'SUPPORTED' })
    if ($supportedDrift.Count -eq $driftOrAbsent.Count) {
        if ($ProcessState.Blocked) {
            $names = ($ProcessState.Running | ForEach-Object { $_.ProcessName }) -join ', '
            return @{
                Value = 'BLOCKED'
                Reasons = @("Active OpenChamber/CPA GUI/OpenCode processes prevent apply: $names")
                ApplyPreconditionSatisfied = $false
            }
        }
        return @{
            Value = 'READY_FOR_GLOBAL_APPLY'
            Reasons = @()
            ApplyPreconditionSatisfied = $true
        }
    }

    return @{
        Value = 'BLOCKED'
        Reasons = @('Target drift is in an indeterminate state.')
        ApplyPreconditionSatisfied = $false
    }
}

$candidate = Get-CandidateState -Root $Root -SimulatedDirty ([bool]$SimulatedDirty)
$processState = Get-ProcessState -SimulatedProcessNames $SimulatedProcessNames
$phaseFive = Get-PhaseFivePackageState -PackagePath $PhaseFivePackagePath -ExpectedHash $PhaseFiveExpectedHash

$targetList = @(Get-FrameworkOwnedTargets) + @($AdditionalTargets)
$targetResults = @()
foreach ($metadata in $targetList) {
    $paths = Resolve-TargetPaths -Metadata $metadata -OpenCodeRoot $OpenCodeRoot -Root $Root
    $drift = Compare-TargetDrift -Metadata $metadata -Paths $paths -Root $Root

    $comparisonMetadata = [ordered]@{
        comparisonType = $metadata.ComparisonType
        sourcePath = if ($metadata.ComparisonType -eq 'semantic-complete') { $paths.CompleteSourcePath } else { $paths.SourcePath }
        mergeSourcePaths = $paths.MergeSourcePaths
        mergeSpec = @($metadata.MergeSpec | ForEach-Object {
                $orderedEntry = [ordered]@{}
                foreach ($key in $_.Keys) {
                    if ($_.ContainsKey($key)) {
                        $orderedEntry[$key] = $_.$key
                    }
                }
                $orderedEntry
            })
    }

    $targetResults += [pscustomobject]@{
        Name = $metadata.Name
        Phase = $metadata.Phase
        Owner = $metadata.Owner
        RelativeTargetPath = $metadata.RelativeTargetPath
        TargetPath = $paths.TargetPath
        SourcePath = $paths.SourcePath
        ComparisonType = $metadata.ComparisonType
        SourceHash = $drift.SourceHash
        TargetHash = $drift.TargetHash
        Match = $drift.Match
        Support = $drift.Support
        Reason = $drift.Reason
        DifferingKeys = $drift.DifferingKeys
        ApplyScripts = $metadata.ApplyScripts
        Verifiers = $metadata.Verifiers
        RollbackSupported = [bool]$metadata.RollbackSupported
        ComparisonMetadata = $comparisonMetadata
    }
}

$verdict = Get-Verdict -Candidate $candidate -ProcessState $processState -PhaseFive $phaseFive -TargetResults $targetResults

$report = [ordered]@{
    candidate = [ordered]@{
        sha = $candidate.Sha
        branch = $candidate.Branch
        clean = $candidate.Clean
        statusShort = $candidate.StatusShort
        root = $candidate.Root
    }
    processState = [ordered]@{
        blocked = $processState.Blocked
        applyPreconditionSatisfied = $verdict.ApplyPreconditionSatisfied
        running = @($processState.Running | ForEach-Object {
                [ordered]@{ processName = $_.ProcessName; id = $_.Id }
            })
    }
    phaseFivePackage = [ordered]@{
        path = $phaseFive.Path
        exists = $phaseFive.Exists
        hash = $phaseFive.Hash
        expectedHash = $phaseFive.ExpectedHash
        match = $phaseFive.Match
    }
    targets = @($targetResults | ForEach-Object {
            [ordered]@{
                name = $_.Name
                phase = $_.Phase
                owner = $_.Owner
                relativeTargetPath = $_.RelativeTargetPath
                targetPath = $_.TargetPath
                sourcePath = $_.SourcePath
                comparisonType = $_.ComparisonType
                sourceHash = $_.SourceHash
                targetHash = $_.TargetHash
                match = $_.Match
                support = $_.Support
                reason = $_.Reason
                differingKeys = $_.DifferingKeys
                applyScripts = $_.ApplyScripts
                verifiers = $_.Verifiers
                rollbackSupported = $_.RollbackSupported
                comparisonMetadata = $_.ComparisonMetadata
            }
        })
    verdict = [ordered]@{
        value = $verdict.Value
        reasons = $verdict.Reasons
        applyPreconditionSatisfied = $verdict.ApplyPreconditionSatisfied
    }
}

if ($Text) {
    "Global apply readiness preflight"
    "============================="
    "Candidate SHA: $($candidate.Sha)"
    "Candidate branch: $($candidate.Branch)"
    "Candidate clean: $($candidate.Clean)"
    "Candidate status: $($candidate.StatusShort)"
    "Active processes blocked: $($processState.Blocked)"
    foreach ($process in $processState.Running) {
        "  - $($process.ProcessName) (PID $($process.Id))"
    }
    "Phase 5 package: $($phaseFive.Path)"
    "Phase 5 match: $($phaseFive.Match) (hash=$($phaseFive.Hash), expected=$($phaseFive.ExpectedHash))"
    ""
    "Targets:"
    foreach ($entry in $targetResults) {
        "  - $($entry.Name) [$($entry.Phase)] owner=$($entry.Owner) -> $($entry.Match)/$($entry.Support) ($($entry.Reason))"
    }
    ""
    "Verdict: $($verdict.Value) (applyPreconditionSatisfied=$($verdict.ApplyPreconditionSatisfied))"
    foreach ($reason in $verdict.Reasons) {
        "  - $reason"
    }
}
elseif (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $parent = Split-Path -Parent $OutputPath
    if ([string]::IsNullOrEmpty($parent)) {
        $parent = '.'
    }
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "OutputPath parent directory does not exist: $parent"
    }
    $json = $report | ConvertTo-Json -Depth 100
    $json | Set-Content -LiteralPath $OutputPath -Encoding Ascii
}
else {
    $report | ConvertTo-Json -Depth 100
}

switch ($verdict.Value) {
    'NO_APPLY_REQUIRED' { exit 0 }
    'READY_FOR_GLOBAL_APPLY' { exit 0 }
    default { exit 2 }
}
