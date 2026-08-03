function Get-CiWindowsOnlyFailures {
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$WorkflowDirectory
    )

    $failures = @()
    if (-not (Test-Path -LiteralPath $WorkflowDirectory -PathType Container)) {
        return "CI workflow directory is missing: $WorkflowDirectory"
    }

    $workflowFiles = @(Get-ChildItem -LiteralPath $WorkflowDirectory -File |
        Where-Object { $_.Extension -in @('.yml', '.yaml') })
    foreach ($workflowFile in $workflowFiles) {
        $ciJobs = @()
        $insideJobs = $false
        $currentJob = $null
        $insideMatrix = $false
        $insideMatrixInclude = $false
        foreach ($line in (Get-Content -LiteralPath $workflowFile.FullName)) {
            if ($line -match '^jobs:\s*(?:#.*)?$') {
                $insideJobs = $true
                continue
            }
            if ($insideJobs -and $line -match '^\S') {
                $insideJobs = $false
                $currentJob = $null
                continue
            }
            if (-not $insideJobs) {
                continue
            }
            if ($line -match '^  ([A-Za-z0-9_-]+):\s*(?:#.*)?$') {
                $currentJob = @{
                    Name = $matches[1]
                    Runner = $null
                    UsesReusableWorkflow = $false
                    MatrixOs = @()
                    HasMatrixInclude = $false
                    MatrixIncludeEntries = 0
                    MatrixIncludeOs = @()
                }
                $ciJobs += $currentJob
                $insideMatrix = $false
                $insideMatrixInclude = $false
                continue
            }
            if ($currentJob -and $line -match '^      matrix:\s*(?:#.*)?$') {
                $insideMatrix = $true
                continue
            }
            if ($currentJob -and $insideMatrix -and $line -match '^      \S') {
                $insideMatrix = $false
                $insideMatrixInclude = $false
            }
            if ($currentJob -and $insideMatrix -and $line -match '^        include:\s*') {
                $currentJob.HasMatrixInclude = $true
                $insideMatrixInclude = $true
                continue
            }
            if ($currentJob -and $insideMatrixInclude -and $line -match '^        \S') {
                $insideMatrixInclude = $false
            }
            if ($currentJob -and $insideMatrixInclude -and $line -match '^          - ') {
                $currentJob.MatrixIncludeEntries += 1
                if ($line -match '^          - os:\s*([^\s#\[\]]+)\s*(?:#.*)?$') {
                    $currentJob.MatrixIncludeOs += $matches[1].Trim().Trim('"').Trim("'")
                }
                continue
            }
            if ($currentJob -and $insideMatrix -and $line -match '^        os:\s*\[(.*?)\]\s*(?:#.*)?$') {
                $currentJob.MatrixOs += @($matches[1].Split(',') |
                    ForEach-Object { $_.Trim().Trim('"').Trim("'") } |
                    Where-Object { $_ })
                continue
            }
            if ($currentJob -and $insideMatrix -and $line -match '^        os:\s*([^\s#\[\]]+)\s*(?:#.*)?$') {
                $currentJob.MatrixOs += $matches[1].Trim().Trim('"').Trim("'")
                continue
            }
            if ($currentJob -and $line -match '^    runs-on:\s*(.+?)\s*(?:#.*)?$') {
                $currentJob.Runner = $matches[1].Trim().Trim('"').Trim("'")
            }
            if ($currentJob -and $line -match '^    uses:\s*') {
                $currentJob.UsesReusableWorkflow = $true
            }
        }

        if ($ciJobs.Count -eq 0) {
            $failures += "CI workflow '$($workflowFile.Name)' must define at least one Windows job."
        }
        foreach ($ciJob in $ciJobs) {
            if ($ciJob.Runner -eq 'windows-latest') {
                continue
            }
            $hasOnlyWindowsMatrixInclude = -not $ciJob.HasMatrixInclude -or
                ($ciJob.MatrixIncludeEntries -gt 0 -and
                    $ciJob.MatrixIncludeOs.Count -eq $ciJob.MatrixIncludeEntries -and
                    @($ciJob.MatrixIncludeOs | Where-Object { $_ -ne 'windows-latest' }).Count -eq 0)
            $hasOnlyWindowsMatrix = $ciJob.Runner -eq '${{ matrix.os }}' -and
                $ciJob.MatrixOs.Count -gt 0 -and
                $hasOnlyWindowsMatrixInclude -and
                @($ciJob.MatrixOs | Where-Object { $_ -ne 'windows-latest' }).Count -eq 0
            if ($hasOnlyWindowsMatrix) {
                continue
            }
            if ($ciJob.Runner -eq '${{ matrix.os }}' -and $ciJob.HasMatrixInclude) {
                $failures += "CI job '$($ciJob.Name)' in $($workflowFile.Name) uses matrix.include with a non-Windows or unverified runner."
                continue
            }
            if ($ciJob.UsesReusableWorkflow) {
                $failures += "CI reusable job '$($ciJob.Name)' in $($workflowFile.Name) cannot prove windows-only because it has no runs-on: windows-latest."
                continue
            }
            $runner = if ($ciJob.Runner) { $ciJob.Runner } else { 'missing' }
            $failures += "CI job '$($ciJob.Name)' in $($workflowFile.Name) must set runs-on: windows-latest; found: $runner."
        }
    }

    return $failures
}

Export-ModuleMember -Function Get-CiWindowsOnlyFailures
