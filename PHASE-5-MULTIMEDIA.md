# Phase 5 Multimedia Layer

Date: 2026-08-02

## Status

Phase 5 is **active**. Global `image_routing: "auto"` strips the parent
attachment before the text-only Terra request, then `observer_attachment`
creates a child Observer session and sends it a structured `FilePart` directly
to M3. The tool waits for M3 and returns its text as the parent tool result.
The metadata gate, strict preflight, and live structured-attachment OCR smoke
all passed again on 2026-08-05.

A documented managed-runtime gate replaces a transport-level parent-media
proof. The structured attachment smoke proves M3 consumed the image by
returning the unique OCR code, but no provider-payload inspection is in
place because that would require dependency instrumentation that this
framework does not own. The limitation is explicit below.

## Evidence Path

The claim needed for activation is not merely that a model advertises vision:
an image attached to a text-only Orchestrator must be saved inside the project,
the attachment must be removed before the Terra request, Observer must read the
saved image through M3, and the result must return to the parent task. A false
positive would either send image bytes to Terra/Sol or claim a successful visual
answer without an Observer read.

The evidence path uses three levels:

| Claim | Evidence | Result |
|---|---|---|
| Direct GPT media is safe | Managed `models cliproxy --verbose` metadata | Refuted: Terra and Sol have `image`, `video`, `pdf`, and `attachment` set to `false`. |
| A usable observer model exists | Managed `models minimax-coding-plan --verbose` metadata | Established for M3 image/video: image and video input plus attachments are `true`; PDF is `false`. |
| Structured child attachment works end to end | Exact global preset, generated PNG with a fresh random OCR code on every run, `scripts\Test-ObserverAttachment.ps1` | Established for the recorded live run: the parent invoked `observer_attachment`, it created a child session with `parentID`, and M3 returned the code that existed only in that run's structured image part. |

`scripts/Test-MultimediaCapabilities.ps1` is the durable metadata gate. It
requires text-only GPT transport, M3 image/video attachment capability, no PDF
claim, and the enabled M3 Observer structured-attachment route. The separate
`Test-ObserverAttachment.ps1` is the end-to-end OCR smoke gate.

`Test-ObserverAttachmentRegression.ps1` is the offline pull-request gate. It
keeps the auto-routing preset, prompt contracts, one-file runtime-patch record,
attached-file invocation, child-session assertion, per-run OCR-code assertion,
and patch metadata (the sole target, exact hash chain, source package identity,
backup/reapply/rollback markers) aligned without calling a provider. It rejects
hash placeholders and distribution paths that do not exist in the npm artifact.

The live smoke preflight fails closed unless the managed package directory and
manifest exist with the `oh-my-opencode-slim@2.2.8` identity, `dist\index.js`
has the exact structured-patch hash, and that bundle contains every reviewed
routing, tool, and registration symbol. It then checks managed runtime config,
loaded prompt contracts, Observer's M3 route, an `auth list` MiniMax entry with
an explicit `api` or `oauth` credential type (not merely a provider name), and
active M3 image-attachment metadata before it creates the fixture or calls a
model. It reports only status and never exposes credential values.

`Test-ObserverAttachmentPreflight.ps1` uses a temporary mock CLI to cover the
managed-command failure branches: binary/workspace availability, config command
failure and invalid JSON, Observer enablement/model, both prompt contracts, a
provider-only auth listing, a missing MiniMax credential, and M3 image metadata.
Each branch verifies its dedicated error and that a credential sentinel cannot
reach output. It performs no provider request and reads no credential value. The
mock-only invocation skips the package cache check so the fixture remains
self-contained on CI; the default `Test-ObserverAttachment.ps1` preflight and
live smoke still require the exact managed bundle, hash, and symbols described
above.

## Source Evidence

The original checkout at `D:\Projects\Docs\oh-my-opencode-slim` is not the
exact npm publish commit. The Phase 5 clone at
`.slim\clonedeps\repos\alvinunreal__oh-my-opencode-slim` is pinned to the npm
record's `218836d6f94fb00943d43f3c64fc3cd835be0ae1` commit; its manifest is
`.slim\clonedeps.json`. It establishes the intended behavior:

| Source | Intended behavior |
|---|---|
| `src\config\loader.ts:203-225` | `image_routing: "auto"` requires Observer enabled. |
| `src\hooks\image-hook.ts:166-282` | Auto mode saves image parts to `.opencode\images`, removes them from the parent message, and adds an Observer path nudge. |
| `src\hooks\image-hook.test.ts:102-140` | Source tests expect auto mode to strip saved image parts and preserve parts if Observer is disabled. |

## Failure And Repair

An isolated temporary project set `disabled_agents` to only `council` and
`image_routing` to `auto`; the M3 Observer configuration and read-only policy
continued to come from the global preset. A real JPEG was attached to the
managed CLI `run` command.

Both attempts failed while loading `oh-my-opencode-slim@2.2.8` with:

```text
disabledTools.filter is not a function
```

The second attempt explicitly supplied an empty `disabled_tools` array. The
same error occurred before the image-routing hook logged an interception.
OpenCode then ran the text-only Orchestrator path, and its delegated Observer
could not access the attachment. This is not a valid Observer media result.

The exact publish source and cached package distribution both contain the same
unsafe health-check expression:

```js
disabledTools.filter(...)
```

`disabled_tools` is optional in the package schema, but the managed runtime
supplied a non-array value during plugin initialization. The default parameter
does not guard non-array values, causing the hook registration to fail after
agents are registered. This explains why Phase 4 agents were visible while slim
hooks were not reliably active.

With explicit approval, a temporary local hotfix was applied to the cached
package. It normalizes the value using `Array.isArray(disabledTools)` before
calling `.filter()`. The reviewed patch source is
`patches\oh-my-opencode-slim-2.2.8-disabled-tools.patch`. The hotfix restores
slim initialization and Phase 4 runtime verification; it does not establish
Observer handoff correctness.

| Target | Before SHA-256 | After SHA-256 | Backup |
|---|---|---|---|
| Cached `dist\index.js` — disabled-tools hotfix | `816D84ABF3DD5923F56DF2C52F3AB7149B46654C3FBBDE9DF8760D22823DEDFC` | `3D70AB6200A5AF7718BFFCF229D985A9C8E2925BA0AD7676046C274E57E65CC5` | `C:\Users\quang\.local\share\opencode\framework-backups\20260802-204959` |
| Cached `dist\index.js` — structured attachment patch | `3D70AB6200A5AF7718BFFCF229D985A9C8E2925BA0AD7676046C274E57E65CC5` | `6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A` | Use the exact timestamped backup directory printed by the patch record's pre-apply block. |
| `oh-my-opencode-slim.json` | `846AB6E27563CF970AB7858A9BA012A824E96DBDEB337D1AE988EAED6CA61245` | Temporarily `3C32F...`, then restored to the before hash | `C:\Users\quang\.local\share\opencode\framework-backups\20260802-205142` |

The hotfix is intentionally temporary: it is outside package management and
will be replaced by a reinstall or plugin update. `autoUpdate` remains `false`.

## Attachment Trace

The end-to-end trace established the following boundaries without recording
image content or prompt text:

1. The managed CLI accepts and resizes the JPEG attachment.
2. `processImageAttachments()` writes one JPEG under
   `.opencode\images\<parent-session>\`.
3. The parent calls `task` for Observer with both `callID` and `sessionID`.
4. A temporary trace patch located the exact session image and confirmed that
   `output.args.prompt` contained its full path before the task ran.
5. M3 Observer starts with that prompt but exits without calling `read`.

The session-scoped path-injection trace was restored from backup
`20260802-213542` because it cannot make the child model consume the image.
That historical patch is no longer active. The runtime now also contains the
reviewed structured-attachment patch described below.

## Structured Handoff

The OpenCode SDK bundled with slim exposes the required primitives:

- `client.session.create({ body: { parentID } })` creates a true child session.
- `client.session.prompt({ body: { agent: 'observer', parts } })` accepts a
  structured `FilePartInput` with `type`, `mime`, `filename`, and data-URL
  `url`.

`observer_attachment` is a synchronous custom tool bundled into the pinned
runtime's sole `dist\index.js`. It accepts one to four PNG, JPEG, GIF, or WebP
images that the parent image hook saved below `.opencode\images`, rejects files
above 10 MiB, creates the Observer child, and returns its result. The bundled
image hook skips an `observer` child so it cannot strip the structured
attachment a second time.

The smoke generates a fresh random eight-character hexadecimal code, renders it
as a hyphenated string in a PNG, attaches the image to a Terra Orchestrator run,
and asserts both an `observer_session_id` and M3's exact per-run OCR output. The
code never appears in the text prompt, so matching it proves M3 consumed that
run's image rather than reusable parent text.

### Transport-Level Parent-Media Proof: Explicit Limitation

A true transport-level proof that the parent message had its image bytes
stripped before the Terra request would require inspecting the actual outbound
HTTP payload to the OpenAI-compatible provider. The framework does not own,
ship, or instrument that transport. Validating the patch only at the source
level is the closest gate available without dependency instrumentation.

Concretely, the framework cannot observe from a script whether the renderer
produced a parent payload without an image part for the Terra request, because
that intercept would require a network capture or a transport-level wrapper
that this framework does not maintain. The active patch record
(`patches\oh-my-opencode-slim-2.2.8-observer-attachment.patch`) records the
sole bundled target, source package identity, backup, exact before/after
SHA-256, reapply, and rollback steps so the patch can be verified at the
package and source level.

The managed-runtime gate that replaces the missing transport-level proof has
four checks and is the strongest durable evidence this framework can produce:

1. The managed package root and `package.json` exist and identify
   `oh-my-opencode-slim@2.2.8`.
2. The cached `dist/index.js` SHA-256 is
   `6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A`,
   the structured patch record's exact after hash.
3. That same bundle contains the Observer skip, attachment nudge,
   `createObserverAttachmentTool` implementation, child `FilePart` data URL,
   `observer_session_id` result, and declaration/initialization/tool-map spread.
4. `scripts/Test-ObserverAttachment.ps1 -PreflightOnly` and a live end-to-end
   OCR smoke both produce `PASS`.

`Test-MultimediaCapabilities.ps1` and `Test-ObserverAttachment.ps1` together
embody this gate. Treat any check failing as a `BLOCKED` condition that warrants
re-deriving the diff at the publish commit before reapplying.

The structured attachment patch is therefore intentionally bounded to
source-level and runtime-metadata evidence. Any parent-payload capture must
be added separately, with its own reviewed patch and a separate gate, before
this section can be reclassified as fully transport-proven.

## Active Policy

- Observer and `image_routing: "auto"` are enabled in the global preset.
- The `observer_attachment` tool is registered by the runtime patch and the
  structured attachment route is currently active; the temporary path-only
  Observer activation was rolled back before this structured handoff replaced
  it.
- Parent images are still removed before Terra/Sol requests. Only the M3
  Observer child receives a structured image attachment.
- Do not send images, video, or PDF to Terra/Sol through OpenCode.
- PDF fallback remains OpenChamber text extraction or selected-page image
  conversion through a separately verified PDF-capable route. Do not represent
  M3 as PDF-capable.

## Maintenance

The runtime patch is outside package management and will be replaced by a
reinstall or slim update. After either event, rerun `Test-AgentLayerRuntime.ps1`,
`Test-MultimediaCapabilities.ps1`, and `Test-ObserverAttachment.ps1`; reapply
the reviewed cache patches only after confirming the same package version,
source package identity, pinned commit, and API shapes. The patch record's
one-file SHA-256 chain must be re-derived at the publish commit before reapply.
PDF remains outside this route.
