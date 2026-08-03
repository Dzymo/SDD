# Phase 5 Multimedia Layer

Date: 2026-08-02

## Status

Phase 5 is **active**. Global `image_routing: "auto"` strips the parent
attachment before the text-only Terra request, then `observer_attachment`
creates a child Observer session and sends it a structured `FilePart` directly
to M3. The tool waits for M3 and returns its text as the parent tool result.

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
| Structured child attachment works end to end | Exact global preset, generated PNG with unique OCR code, `scripts\Test-ObserverAttachment.ps1` | Established: the parent invokes `observer_attachment`, it creates a child session with `parentID`, M3 receives the structured image part, and returns `K7N4-Q2P9`. |

`scripts/Test-MultimediaCapabilities.ps1` is the durable metadata gate. It
requires text-only GPT transport, M3 image/video attachment capability, no PDF
claim, and the enabled M3 Observer structured-attachment route. The separate
`Test-ObserverAttachment.ps1` is the end-to-end OCR smoke gate.

`Test-ObserverAttachmentRegression.ps1` is the offline pull-request gate. It
keeps the auto-routing preset, prompt contracts, runtime-patch record, image
fixture, attached-file invocation, child-session assertion, and unique OCR-code
assertion aligned without calling a provider.

The live smoke preflight checks managed runtime config, loaded prompt contracts,
Observer's M3 route, MiniMax credential presence through `auth list`, and M3
active image-attachment metadata before it creates the fixture or calls either
model. It reports only status and never exposes credential values.

`Test-ObserverAttachmentPreflight.ps1` covers every preflight failure branch
with a temporary mock CLI: binary/workspace availability, managed config command
failure and invalid JSON, Observer enablement/model, both prompt contracts,
MiniMax credential, and M3 image metadata. Each branch verifies its dedicated
error and that a credential sentinel cannot reach output. It is safe for hosted
Windows CI because it performs no provider request and reads no real credential.

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
| Cached `dist\index.js` | `816D84ABF3DD5923F56DF2C52F3AB7149B46654C3FBBDE9DF8760D22823DEDFC` | `3D70AB6200A5AF7718BFFCF229D985A9C8E2925BA0AD7676046C274E57E65CC5` | `C:\Users\quang\.local\share\opencode\framework-backups\20260802-204959` |
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

`observer_attachment` is a synchronous custom tool in the pinned runtime
package. It accepts only PNG, JPEG, GIF, or WebP images that the parent image
hook saved below `.opencode\images`, rejects files above 10 MiB, creates the
Observer child, and returns its result. The image hook skips an `observer`
child so it cannot strip the structured attachment a second time.

The smoke generates a PNG containing `K7N4-Q2P9`, attaches it to a Terra
Orchestrator run, and asserts both an `observer_session_id` and M3's exact OCR
output. The marker never appears in the text prompt, so matching it proves
M3 consumed the image rather than parent text.

## Active Policy

- Observer and `image_routing: "auto"` are enabled in the global preset.
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
the reviewed cache patches only after confirming the same package version and
API shapes. PDF remains outside this route.
