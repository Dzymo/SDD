# Phase 4 Agent Layer

Date: 2026-08-02

## Result

The standalone managed OpenChamber OpenCode binary loads the pinned
`oh-my-opencode-slim@2.2.8` plugin and the `sdd-personal` preset. The default
agent is Orchestrator. Explorer, Librarian, Oracle, Designer, and Fixer are
registered; Council and Observer are disabled. After restart, the user confirmed
these six required agents appear in the OpenChamber UI.

The implementation deliberately does not alter the CPA GUI-managed
`opencode.json`, its sidecar, any OpenChamber configuration/state, or provider
credentials.

## Applied Files

| Target | Before state | Before SHA-256 | After SHA-256 |
|---|---|---|---|
| `C:\Users\quang\.config\opencode\opencode.jsonc` | Existing schema-only overlay | `4E901F9E457C8D52AB31F9FB4EA637A8C9104EBDBF23FE8B3600F35AD46D4A61` | `04C2B4A83DBD1ED49DD6036A048812D463FF188412FD219D4EEAC4CA31FF2B59` |
| `C:\Users\quang\.config\opencode\oh-my-opencode-slim.json` | Absent | N/A | `846AB6E27563CF970AB7858A9BA012A824E96DBDEB337D1AE988EAED6CA61245` |
| `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md` | Absent | N/A | `5E93A39811BC596CDED810E48016AA3C2360668EB5D5C675BE18D468598B009E` |
| `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\explorer.md` | Absent | N/A | `2B19A61674E7B3FC5CD16D2240149C4E133B6A15126457E4B0B637A8FBFAF1FF` |
| `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\librarian.md` | Absent | N/A | `61014F072F0C767E3890E06B61CC324CD5970DF903C895E26FD459C3D70CDA87` |

Protected backup: `C:\Users\quang\.local\share\opencode\framework-backups\20260802-201629`.

## Effective Safety Policy

- Slim's non-OAuth Context7, websearch, and GitHub-search MCP defaults are
  disabled. No Phase 3 MCP is installed or represented as active.
- Explorer, Librarian, and Oracle have verified denials for edit, shell,
  delegation, and external-directory access. Observer has the same policy in
  its retained configuration. Phase 5 later enabled it after the structured
  attachment smoke test passed; see `PHASE-5-MULTIMEDIA.md`.
- Slim idle continuation, multiplexer, companion, Council, and its worktrees
  skill are disabled. OpenChamber keeps ownership of continuation and worktrees.

## Verification

| Claim | Command or source | Result |
|---|---|---|
| Source routes, fallback chains, permissions, prompts, and feature flags are valid | `scripts\Test-AgentLayer.ps1` | PASS |
| Research source schema remains valid | `scripts\Test-ResearchConfigSchema.ps1` | PASS |
| Framework contains only reviewed source and no credential markers | `scripts\Test-FrameworkSkeleton.ps1` | PASS |
| Managed OpenCode loads the plugin, expected primary routes, active agents, no default MCPs, and read-only runtime permission denials | `scripts\Test-AgentLayerRuntime.ps1` | PASS |

The runtime verifier establishes enforced permission policy and model primary
routes. The plugin stores fallback variants in its internal ordered model chain,
so those pairs are verified from the reviewed source rather than inferred from
`opencode debug config` output.

## Restart and Rollback

The standalone managed CLI validated the persisted files, and the user confirmed
the required agents in the restarted OpenChamber UI. To roll back, follow
`docs/rollback.md` and restore only the files in the table from the protected
backup.
