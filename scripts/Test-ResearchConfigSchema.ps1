[CmdletBinding()]
param(
    [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

function Get-JsonProperties {
    param([object]$Value)

    if ($null -eq $Value -or $Value -is [System.Array] -or $Value -is [string]) {
        return @()
    }

    return @($Value.PSObject.Properties)
}

function Test-JsonType {
    param(
        [object]$Value,
        [string]$Type
    )

    switch ($Type) {
        'object' { return $null -ne $Value -and $Value -isnot [System.Array] -and $Value -isnot [string] }
        'array' { return $Value -is [System.Array] }
        'string' { return $Value -is [string] }
        'boolean' { return $Value -is [bool] }
        'number' { return $Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64] -or $Value -is [single] -or $Value -is [double] -or $Value -is [decimal] }
        'null' { return $null -eq $Value }
        default { throw "Unsupported JSON Schema type: $Type" }
    }
}

function Test-JsonEqual {
    param(
        [object]$Actual,
        [object]$Expected
    )

    if ($Actual -is [System.Array] -or $Expected -is [System.Array]) {
        if ($Actual -isnot [System.Array] -or $Expected -isnot [System.Array] -or $Actual.Count -ne $Expected.Count) {
            return $false
        }
        for ($index = 0; $index -lt $Actual.Count; $index++) {
            if (-not (Test-JsonEqual -Actual $Actual[$index] -Expected $Expected[$index])) {
                return $false
            }
        }
        return $true
    }

    return $Actual -ceq $Expected
}

function Test-JsonSchemaValue {
    param(
        [object]$Value,
        [object]$Schema,
        [string]$Path,
        [System.Collections.ArrayList]$Failures
    )

    if ($null -ne $Schema.type -and -not (Test-JsonType -Value $Value -Type $Schema.type)) {
        [void]$Failures.Add("${Path}: expected type '$($Schema.type)'")
        return
    }

    if ($null -ne $Schema.PSObject.Properties['const'] -and -not (Test-JsonEqual -Actual $Value -Expected $Schema.const)) {
        [void]$Failures.Add("${Path}: does not match its required constant")
        return
    }

    if ($Schema.type -eq 'object') {
        $valueProperties = @(Get-JsonProperties -Value $Value)
        $valueNames = @($valueProperties | ForEach-Object { $_.Name })
        $schemaProperties = $Schema.properties
        $allowedNames = @($schemaProperties.PSObject.Properties | ForEach-Object { $_.Name })

        foreach ($requiredName in @($Schema.required)) {
            if ($valueNames -notcontains $requiredName) {
                [void]$Failures.Add("${Path}: missing required property '$requiredName'")
            }
        }

        if ($Schema.additionalProperties -eq $false) {
            foreach ($valueName in $valueNames) {
                if ($allowedNames -notcontains $valueName) {
                    [void]$Failures.Add("${Path}: unapproved property '$valueName'")
                }
            }
        }

        foreach ($property in $schemaProperties.PSObject.Properties) {
            $valueProperty = $valueProperties | Where-Object { $_.Name -eq $property.Name }
            if ($null -ne $valueProperty) {
                Test-JsonSchemaValue -Value $valueProperty.Value -Schema $property.Value -Path "$Path.$($property.Name)" -Failures $Failures
            }
        }
    }
}

$schemaPath = Join-Path $Root 'config\opencode\research-mcp.schema.json'
$validFixturePath = Join-Path $Root 'fixtures\phase-3\research-mcp.valid.json'
$invalidFixturePaths = @(
    (Join-Path $Root 'fixtures\phase-3\research-mcp.invalid-auth.json'),
    (Join-Path $Root 'fixtures\phase-3\research-mcp.invalid-command.json'),
    (Join-Path $Root 'fixtures\phase-3\research-mcp.invalid-url.json')
)

foreach ($path in @($schemaPath, $validFixturePath) + $invalidFixturePaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required schema test input not found: $path"
    }
}

try {
    $schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Schema is not valid JSON: $schemaPath. $($_.Exception.Message)"
}

if ($schema.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema') {
    throw 'Schema must declare JSON Schema draft 2020-12.'
}

$validFixture = Get-Content -LiteralPath $validFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
$validFailures = [System.Collections.ArrayList]@()
Test-JsonSchemaValue -Value $validFixture -Schema $schema -Path '$' -Failures $validFailures
if ($validFailures.Count -gt 0) {
    $validFailures | ForEach-Object { "FAIL: valid fixture: $_" }
    exit 1
}

$failures = [System.Collections.ArrayList]@()
foreach ($invalidFixturePath in $invalidFixturePaths) {
    $fixture = Get-Content -LiteralPath $invalidFixturePath -Raw | ConvertFrom-Json -ErrorAction Stop
    $fixtureFailures = [System.Collections.ArrayList]@()
    Test-JsonSchemaValue -Value $fixture -Schema $schema -Path '$' -Failures $fixtureFailures
    if ($fixtureFailures.Count -eq 0) {
        [void]$failures.Add("Invalid fixture was accepted: $invalidFixturePath")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { "FAIL: $_" }
    exit 1
}

'Phase 3 research MCP schema: PASS'
