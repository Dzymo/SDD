[CmdletBinding()]
param(
    [string]$Root
)

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
        [string]$Text,
        [string]$Expected,
        [string]$Message
    )

    Assert-True -Condition $Text.Contains($Expected) -Message $Message
}

function Read-RequiredText {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required regression source not found: $Path"
    }
    return Get-Content -LiteralPath $Path -Raw
}

$phase5Path = Join-Path $Root 'PHASE-5-MULTIMEDIA.md'
$phase6Path = Join-Path $Root 'PHASE-6-OPENSPEC-PROJECT-TEMPLATE.md'
$rollbackPath = Join-Path $Root 'docs\rollback.md'
$applyCmdPath = Join-Path $Root 'templates\project\.opencode\commands\opsx-apply.md'
$archiveCmdPath = Join-Path $Root 'templates\project\.opencode\commands\opsx-archive.md'
$syncCmdPath = Join-Path $Root 'templates\project\.opencode\commands\opsx-sync.md'
$bootstrapReadmePath = Join-Path $Root 'templates\project\README.md'

$phase5 = Read-RequiredText -Path $phase5Path
$phase6 = Read-RequiredText -Path $phase6Path
$rollback = Read-RequiredText -Path $rollbackPath
$applyCmd = Read-RequiredText -Path $applyCmdPath
$archiveCmd = Read-RequiredText -Path $archiveCmdPath
$syncCmd = Read-RequiredText -Path $syncCmdPath
$bootstrapReadme = Read-RequiredText -Path $bootstrapReadmePath

# --- Preset and prompt contracts -------------------------------------------------

$presetPath = Join-Path $Root 'config\oh-my-opencode-slim\sdd-personal.json'
$preset = Read-RequiredText -Path $presetPath | ConvertFrom-Json -ErrorAction Stop
Assert-True -Condition (-not ($preset.disabled_agents -contains 'observer')) -Message 'Observer must remain enabled for structured image handoff.'
Assert-True -Condition ($preset.image_routing -eq 'auto') -Message 'Parent image routing must remain in auto mode.'

$promptRoot = Join-Path $Root 'prompts\oh-my-opencode-slim\sdd-personal'
$orchestrator = Read-RequiredText -Path (Join-Path $promptRoot 'orchestrator.md')
Assert-Contains -Text $orchestrator -Expected 'observer_attachment' -Message 'Orchestrator must route saved images through observer_attachment.'
Assert-Contains -Text $orchestrator -Expected 'Do not use `task`' -Message 'Orchestrator must not regress to path-only task handoff.'

$observer = Read-RequiredText -Path (Join-Path $promptRoot 'observer.md')
Assert-Contains -Text $observer -Expected 'structured attachments' -Message 'Observer must accept direct structured attachments.'
Assert-Contains -Text $observer -Expected 'MUST call `read`' -Message 'Observer must retain the path-only fallback rule.'

# --- Smoke script contract -------------------------------------------------------

$smoke = Read-RequiredText -Path (Join-Path $Root 'scripts\Test-ObserverAttachment.ps1')
Assert-Contains -Text $smoke -Expected 'if ([string]::IsNullOrWhiteSpace($Workspace))' -Message 'The smoke must initialize its workspace after script scope is available.'
$preflightSource = Read-RequiredText -Path (Join-Path $Root 'scripts\Test-ObserverAttachmentPreflight.ps1')
Assert-Contains -Text $smoke -Expected "@('debug', 'config')" -Message 'The smoke must preflight the managed runtime configuration.'
Assert-Contains -Text $smoke -Expected "@('auth', 'list')" -Message 'The smoke must preflight MiniMax credential availability without reading a token.'
Assert-Contains -Text $smoke -Expected "@('models', 'minimax-coding-plan', '--verbose')" -Message 'The smoke must preflight the active M3 image-attachment route.'
Assert-Contains -Text $smoke -Expected 'Observer OCR preflight: PASS' -Message 'The smoke must report a completed preflight before the model call.'
Assert-Contains -Text $smoke -Expected "[Guid]::NewGuid()" -Message 'The smoke must generate a fresh OCR code for every run.'
Assert-Contains -Text $smoke -Expected 'DrawString($ocrCode' -Message 'The smoke image must contain the per-run OCR code.'
Assert-Contains -Text $smoke -Expected '[regex]::Escape($ocrCode)' -Message "The smoke must require M3 to return that run's OCR code."
Assert-True -Condition (-not $smoke.Contains('K7N4-Q2P9')) -Message 'The smoke must not use the obsolete fixed OCR code.'
Assert-Contains -Text $smoke -Expected '--file $imagePath' -Message 'The smoke must attach the generated image to OpenCode.'
Assert-Contains -Text $smoke -Expected 'observer_session_id' -Message 'The smoke must require a child Observer session.'
Assert-Contains -Text $smoke -Expected '6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A' -Message 'The smoke must require the exact structured-patch dist/index.js hash.'
Assert-Contains -Text $smoke -Expected 'Test-RuntimePatchPresence -Path $distIndex -ExpectedAfterHash $expectedDistIndex' -Message 'The smoke must fail closed on a missing or mismatched dist/index.js.'
Assert-Contains -Text $smoke -Expected 'if (-not $SkipRuntimePatchPreflightForMock)' -Message 'The default smoke must retain runtime-patch preflight unless the mock-only switch is explicitly supplied.'
Assert-Contains -Text $smoke -Expected 'function createObserverAttachmentTool(options)' -Message 'The smoke must require the structured attachment implementation symbol.'
Assert-Contains -Text $smoke -Expected 'let observerAttachmentTools;' -Message 'The smoke must require the tool declaration symbol.'
Assert-Contains -Text $smoke -Expected '...observerAttachmentTools' -Message 'The smoke must require the tool-map spread symbol.'
Assert-Contains -Text $preflightSource -Expected 'Provider name without credential' -Message 'Negative preflight coverage must prove a provider name alone is not accepted as auth.'
Assert-Contains -Text $preflightSource -Expected '-SkipRuntimePatchPreflightForMock' -Message 'The temporary mock preflight must explicitly bypass only the unavailable local package-cache gate.'

# --- Structured attachment patch record ------------------------------------------

$runtimePatchLines = Get-Content -LiteralPath (Join-Path $Root 'patches\oh-my-opencode-slim-2.2.8-observer-attachment.patch')
$runtimePatch = ($runtimePatchLines -join "`n")
Assert-Contains -Text $runtimePatch -Expected 'createObserverAttachmentTool' -Message 'The runtime patch record must retain the structured child-session tool.'
Assert-Contains -Text $runtimePatch -Expected 'msg.info.agent === "observer"' -Message 'The runtime patch record must preserve Observer attachments from re-stripping.'
Assert-Contains -Text $runtimePatch -Expected 'Call observer_attachment with every file path above.' -Message 'The runtime patch record must nudge the parent to use observer_attachment.'
Assert-Contains -Text $runtimePatch -Expected 'do not use task or read for this handoff' -Message 'The runtime patch record must prohibit path-only task/read handoff.'
Assert-Contains -Text $runtimePatch -Expected 'const observer_attachment = tool5({' -Message 'The structured tool must use the bundled tool5 interface.'
Assert-Contains -Text $runtimePatch -Expected 'files: z7.array(z7.string().min(1)).min(1).max(4)' -Message 'The structured tool must use z7 and limit each request to four files.'
Assert-Contains -Text $runtimePatch -Expected 'path22.resolve(worktree, ".opencode", "images")' -Message 'The structured tool must constrain files to the bundled path22 image root.'
Assert-Contains -Text $runtimePatch -Expected 'fs9.readFileSync(absolutePath)' -Message 'The structured tool must read validated files through the bundled fs9 interface.'
Assert-Contains -Text $runtimePatch -Expected 'type: "file"' -Message 'The structured tool must create FilePart data.'
Assert-Contains -Text $runtimePatch -Expected 'observer_session_id:' -Message 'The structured tool must return its Observer child session ID.'
Assert-Contains -Text $runtimePatch -Expected 'let observerAttachmentTools;' -Message 'OhMyOpenCodeLite must declare the attachment tools.'
Assert-Contains -Text $runtimePatch -Expected 'observerAttachmentTools = createObserverAttachmentTool({' -Message 'OhMyOpenCodeLite must initialize the attachment tools.'
Assert-Contains -Text $runtimePatch -Expected '...observerAttachmentTools' -Message 'OhMyOpenCodeLite must spread the attachment tools into its tool map.'
Assert-Contains -Text $runtimePatch -Expected '# Source package identity' -Message 'The runtime patch record must document its source package identity.'
Assert-Contains -Text $runtimePatch -Expected '# Target file paths' -Message 'The runtime patch record must list its target file paths.'
Assert-Contains -Text $runtimePatch -Expected '# Before SHA-256' -Message 'The runtime patch record must record before SHA-256 values.'
Assert-Contains -Text $runtimePatch -Expected '# After SHA-256' -Message 'The runtime patch record must record after SHA-256 values.'
Assert-Contains -Text $runtimePatch -Expected '# Pre-apply backup' -Message 'The runtime patch record must document its pre-apply backup procedure.'
Assert-Contains -Text $runtimePatch -Expected '# Apply (PowerShell 5.1)' -Message 'The runtime patch record must document its apply procedure.'
Assert-Contains -Text $runtimePatch -Expected '# Rollback (PowerShell 5.1)' -Message 'The runtime patch record must document its rollback procedure.'

# The patch must record the exact npm identity and the real one-file hash chain.
Assert-Contains -Text $runtimePatch -Expected '218836d6f94fb00943d43f3c64fc3cd835be0ae1' -Message 'The runtime patch record must pin the same npm gitHead commit as the cloned source.'
Assert-Contains -Text $runtimePatch -Expected '816D84ABF3DD5923F56DF2C52F3AB7149B46654C3FBBDE9DF8760D22823DEDFC' -Message 'The runtime patch record must record the publish-baseline dist/index.js SHA-256.'
Assert-Contains -Text $runtimePatch -Expected '3D70AB6200A5AF7718BFFCF229D985A9C8E2925BA0AD7676046C274E57E65CC5' -Message 'The runtime patch record must use the disabled-tools-hotfix hash as its before SHA-256.'
Assert-Contains -Text $runtimePatch -Expected '6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A' -Message 'The runtime patch record must record the structured-patch after SHA-256.'
Assert-True -Condition ($runtimePatch -notmatch '(?i)(HASH_PENDING|PENDING_RECONFIRM|PLACEHOLDER_HASH|ABSENT_BEFORE_PATCH)') -Message 'The runtime patch record must reject placeholder hash values.'

$obsoletePatchTargets = @(
    'dist/hooks/image-hook.js',
    'dist/tools/observer-attachment.js',
    'dist/tools/index.js',
    'src/hooks/image-hook.ts',
    'src/index.ts'
)
foreach ($obsoleteTarget in $obsoletePatchTargets) {
    Assert-True -Condition (-not $runtimePatch.Contains($obsoleteTarget)) -Message "The runtime patch record must not name obsolete target $obsoleteTarget."
}
$oldDiffHeaders = @($runtimePatchLines | Where-Object { $_ -match '^--- ' })
$newDiffHeaders = @($runtimePatchLines | Where-Object { $_ -match '^\+\+\+ ' })
$hunkHeaders = @($runtimePatchLines | Where-Object { $_ -match '^@@ ' })
Assert-True -Condition ($oldDiffHeaders.Count -eq 1 -and $oldDiffHeaders[0] -ceq '--- a/dist/index.js') -Message 'The unified diff must have exactly one old target: a/dist/index.js.'
Assert-True -Condition ($newDiffHeaders.Count -eq 1 -and $newDiffHeaders[0] -ceq '+++ b/dist/index.js') -Message 'The unified diff must have exactly one new target: b/dist/index.js.'
Assert-True -Condition ($hunkHeaders.Count -eq 5) -Message 'The one-file unified diff must contain the five physical ranges implementing the four reviewed structured changes.'

# --- Phase 5 documentation must reflect the active multimedia activation ---------

Assert-Contains -Text $phase5 -Expected 'structured attachment route is currently active' -Message 'Phase 5 doc must state that the structured attachment route is the active multimedia activation.'
Assert-Contains -Text $phase5 -Expected 'managed-runtime gate replaces a transport-level parent-media' -Message 'Phase 5 doc must explicitly state the transport-level limitation.'
Assert-Contains -Text $phase5 -Expected 'framework cannot observe from a script whether the renderer' -Message 'Phase 5 doc must explain why a transport-level parent-media proof is absent without dependency instrumentation.'
Assert-Contains -Text $phase5 -Expected 'managed package root and `package.json` exist' -Message 'Phase 5 doc must list the fail-closed package identity gate.'
Assert-Contains -Text $phase5 -Expected '6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A' -Message 'Phase 5 doc must list the exact structured-patch after hash.'
Assert-Contains -Text $phase5 -Expected 'That same bundle contains the Observer skip' -Message 'Phase 5 doc must list the bundled symbol gate.'
Assert-Contains -Text $phase5 -Expected 'fresh random eight-character hexadecimal code' -Message 'Phase 5 doc must describe the per-run OCR evidence.'

# --- Rollback doc must accurately say multimedia activation is active -----------

Assert-Contains -Text $rollback -Expected 'two temporary package-cache hotfixes active' -Message 'Rollback doc must reflect the number of active runtime patches.'
Assert-Contains -Text $rollback -Expected 'attachment route is the live multimedia activation' -Message 'Rollback doc must state that the structured attachment route is the live multimedia activation.'
Assert-Contains -Text $rollback -Expected 'same bundled file in a strict hash chain' -Message 'Rollback doc must preserve patch ordering.'
Assert-Contains -Text $rollback -Expected 'oh-my-opencode-slim@2.2.8\node_modules\oh-my-opencode-slim\dist\index.js' -Message 'Rollback doc must list dist/index.js as the sole structured attachment target.'
Assert-Contains -Text $rollback -Expected 'exact timestamped backup directory printed' -Message 'Rollback doc must require the exact file-level backup from pre-apply.'
Assert-Contains -Text $rollback -Expected 'patches\oh-my-opencode-slim-2.2.8-observer-attachment.patch' -Message 'Rollback doc must reference the structured attachment patch record.'

# --- Phase 6 documentation must mention the new gates ----------------------------

Assert-Contains -Text $phase6 -Expected '`/opsx-archive` prompt now enforces a release, approval, and' -Message 'Phase 6 doc must describe the framework release/approval gate.'
Assert-Contains -Text $phase6 -Expected 'installed-CLI recovery' -Message 'Phase 6 doc must describe the concrete installed-CLI recovery flow for the missing continuation command.'
Assert-Contains -Text $phase6 -Expected 'is not gated by release, approval, or pre-release validation' -Message 'Phase 6 gap table must describe the missing release/approval gates.'

# --- Bootstrap README and command source must agree on the recovery flow ---------

Assert-Contains -Text $applyCmd -Expected 'openspec instructions <artifact-id> --change "<name>" --json' -Message 'opsx-apply must include the concrete installed-CLI recovery flow.'
Assert-Contains -Text $applyCmd -Expected 'provides no built-in continuation surface' -Message 'opsx-apply must document that the core profile provides no continuation surface.'
Assert-True -Condition (-not $applyCmd.Contains('/opsx-continue')) -Message 'opsx-apply must not defer to /opsx-continue for blocked changes.'

Assert-Contains -Text $archiveCmd -Expected 'openspec archive <change-name>' -Message 'opsx-archive must use the installed CLI on Windows instead of mkdir -p.'
Assert-True -Condition (-not $archiveCmd.Contains('mkdir -p')) -Message 'opsx-archive must not contain the POSIX mkdir -p step.'
Assert-Contains -Text $archiveCmd -Expected 'Enforce framework release and approval gates before archive' -Message 'opsx-archive must include the framework release/approval gate.'
Assert-Contains -Text $archiveCmd -Expected 'Pre-release validation gate' -Message 'opsx-archive must include a pre-release validation gate.'
Assert-Contains -Text $archiveCmd -Expected 'Verification gate' -Message 'opsx-archive must include a verification gate.'
Assert-Contains -Text $archiveCmd -Expected 'OpenSpec archive is forbidden without a successful recorded release' -Message 'opsx-archive must forbid archive without a recorded release for public-boundary changes.'
Assert-True -Condition (-not $archiveCmd.Contains('Proceed if user confirms')) -Message 'opsx-archive must not allow user confirmation to bypass incomplete artifacts or tasks.'
Assert-True -Condition (-not $archiveCmd.Contains('archived as "no release"')) -Message 'opsx-archive must not offer a no-release archive path.'
Assert-Contains -Text $archiveCmd -Expected 'checkbox `- [ ]' -Message 'opsx-archive must inspect unchecked tasks before archive.'
Assert-Contains -Text $archiveCmd -Expected '/opsx-apply <name>' -Message 'opsx-archive must return incomplete work to opsx-apply.'
Assert-Contains -Text $archiveCmd -Expected 'Không tự thực hiện task' -Message 'opsx-archive must not implement or mark incomplete tasks during archive.'

Assert-Contains -Text $syncCmd -Expected 'giữ `--store <id>' -Message 'opsx-sync must preserve the selected store argument.'
Assert-Contains -Text $syncCmd -Expected 'specification root do store metadata/CLI trả về' -Message 'opsx-sync must resolve the selected store specification root.'
Assert-Contains -Text $syncCmd -Expected 'dừng `BLOCKED' -Message 'opsx-sync must fail closed when a store destination cannot be proven.'

Assert-Contains -Text $bootstrapReadme -Expected 'openspec instructions <artifact-id> --change <name> --json' -Message 'Bootstrap README must document the concrete installed-CLI recovery flow.'
Assert-True -Condition (-not $bootstrapReadme.Contains('/opsx-continue')) -Message 'Bootstrap README must not reference the missing /opsx-continue command.'

'Observer attachment regression source: PASS'
