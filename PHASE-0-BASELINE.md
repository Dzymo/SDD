# Phase 0 Baseline and Ownership

Date: 2026-08-02

## Scope and Result

This report establishes the read-only baseline required before changing the
personal OpenCode framework. No OpenCode or OpenChamber configuration was
modified during Phase 0. No backups containing configuration content were
created in `D:\Projects\SDD`.

Phase 0 is complete as a readiness baseline. It does not authorize a global
configuration write. Phase 1 must use the managed OpenChamber binary and must
benchmark the CPA GUI route because its exposed metadata does not declare
reasoning variants or useful context limits.

## Effective Runtime Inventory

| Component | Evidence | Result |
|---|---|---|
| Shell `opencode` command | `opencode --version` | `1.18.5` from `C:\Users\quang\AppData\Roaming\npm\opencode.ps1` |
| OpenChamber | `OpenChamber.exe` version metadata | `1.17.1` |
| OpenChamber bundled OpenCode | bundled `opencode.exe --version` | `1.18.9` |
| Active OpenCode server | `managed-opencode\5084.json` and process inspection | PID `5084`, started by OpenChamber, bundled `opencode.exe` |
| CPA GUI proxy | process inspection | EasyCLIProxyAPI and `cli-proxy-api` are running; the configured local endpoint is `http://127.0.0.1:8317/v1` |

The shell CLI and the OpenChamber-managed CLI are different binaries and have
different versions. Framework verification that affects OpenChamber must run
against the bundled `1.18.9` binary, not only against the shell `1.18.5`
wrapper.

## Ownership and Configuration Boundaries

| Asset | Observed owner | Evidence | Write decision | Rollback owner/path |
|---|---|---|---|---|
| `C:\Users\quang\.config\opencode\opencode.json` | CPA GUI-managed global config | Adjacent `opencode.json.cpa-gui.state.json` identifies client `opencode`, selected model, and shares the exact modification time | Do not edit directly. Use a CPA GUI-supported mechanism or a proven overlay only. | CPA GUI-compatible restore from a protected local backup; validate with the managed binary. |
| `C:\Users\quang\.config\opencode\opencode.json.cpa-gui.state.json` | CPA GUI | Sidecar naming and synchronized modification time | Never edit through this framework. | CPA GUI only. |
| `C:\Users\quang\.config\opencode\opencode.jsonc` | User/OpenCode global configuration layer | Minimal schema-only file; no manager evidence | Read-only until a future change has a validated ownership decision. | Protected local backup and managed-binary validation. |
| OpenChamber runtime plugin injection | OpenChamber | `OPENCODE_CONFIG_CONTENT` adds `openchamber-plugin.js`; removing it from a one-shot CLI process removes the plugin from `debug config` | Do not reproduce or replace this injection. | OpenChamber restart/recovery owns this runtime state. |
| `C:\Users\quang\.config\openchamber\settings.json` | OpenChamber | Contains relay private keys, session permission state, local project data, and desktop state | Never edit or back up through the framework. | OpenChamber only. |
| `C:\Users\quang\.config\openchamber\managed-opencode\*.json` | OpenChamber runtime | Current PID, owner PID, port, bundled binary, and start time | Runtime state: never edit or restore. | OpenChamber restart recreates it. |
| `C:\Users\quang\.config\openchamber\agent-tool\openchamber-plugin.js` | OpenChamber installation/runtime | Active plugin origin reported by `opencode debug config` | Never edit through the framework. | OpenChamber repair/update/restart. |
| Future framework files under `D:\Projects\SDD` | This framework | This report and `PLAN.md` | Safe source-controlled assets only; no credentials or user state. | File-level restore from the framework repository/history. |

OpenChamber is operating in **managed OpenCode mode**, not external mode:
`managed-opencode\5084.json` records desktop runtime, the bundled binary, and
an OpenChamber owner PID; the managed PID was live during inspection. The
interactive session also exposes `OPENCODE_BINARY` pointing to the same bundled
binary and `OPENCODE_CONFIG_CONTENT` for OpenChamber's runtime plugin.

## Effective Configuration State

`opencode debug config` succeeded. The persistent global configuration selects
`cpa-gui/gpt-5.6-sol`, defines `cliproxy` and `cpa-gui`, and uses `pwsh`.

The effective runtime config also contains:

- the OpenChamber agent-tool plugin from
  `file:///C:/Users/quang/.config/openchamber/agent-tool/openchamber-plugin.js`;
- an empty inline agent map, mode map, and command map;
- no configured MCP server;
- no configured oh-my-opencode-slim plugin;
- no global agent, command, plugin, or MCP directories.

The active agents are OpenCode built-ins only: `build`, `plan`, `explore`,
`general`, plus internal primary agents `compaction`, `summary`, and `title`.

The global skills directory contains eight installed skills:

- `clonedeps`
- `codemap`
- `deepwork`
- `oh-my-opencode-slim`
- `reflect`
- `simplify`
- `verification-planning`
- `worktrees`

The installed global npm dependency inventory is
`@opencode-ai/plugin@1.18.4`. The skill named `oh-my-opencode-slim` is present,
but `debug config` does not show an active slim plugin.

## Permissions Baseline

`opencode agent list` reports the built-in policy stack. The key effective
boundaries are:

| Agent | Mode | Effective capability summary |
|---|---|---|
| `build` | primary | Broad tool access; `.env` reads ask; external directories ask except listed OpenCode paths. |
| `plan` | primary | Edits denied except plan files; general subagent delegation is denied. |
| `explore` | subagent | Broad read/search/web/shell access; no explicit framework read-only shell restriction yet. |
| `general` | subagent | Broad default access; `todowrite` denied. |
| `compaction`, `summary`, `title` | internal primary | Final deny-all override except OpenCode tool-output access. |

No dedicated Librarian, Explorer, Oracle, Observer, Designer, or Fixer agent
exists yet. Phase 4 must introduce those agents with explicit per-agent
permissions; it must not infer safety from agent names.

## Model Metadata Baseline

The following is the exact metadata exposed by `opencode models --verbose` for
the relevant routes. It is OpenCode transport metadata, not a claim about an
underlying model's native capabilities.

| Route(s) | Status | Input media | Attachment | Tool call | Reasoning / variants | Limits |
|---|---|---|---:|---:|---|---|
| `cpa-gui/gpt-5.6-sol`, `-sol-med`, `-sol-high`, `-sol-xhigh` | active | text only | false | true | reasoning false; variants `{}` for every exposed route | context `0`, output `0` |
| `cpa-gui/gpt-5.6-terra`, `-terra-med`, `-terra-high`, `-terra-xhigh` | active | text only | false | true | reasoning false; variants `{}` for every exposed route | context `0`, output `0` |
| `minimax-coding-plan/MiniMax-M3` | active | text, image, video; no PDF | true | true | reasoning true; `none` sets thinking disabled; `thinking` sets adaptive thinking | context `1,000,000`, output `128,000` |

Consequences:

1. CPA GUI effort mapping is **unverified**, not assumed. The route names
   distinguish `med`, `high`, and `xhigh`, but OpenCode metadata does not
   expose a reasoning capability or variant mapping for them.
2. CPA GUI is currently **text-only** at the OpenCode transport boundary.
   Image and PDF support must not be claimed or configured from underlying
   model knowledge.
3. MiniMax M3's `none` and `thinking` variants are positively evidenced in the
   current metadata. Its image and video support are also positively evidenced;
   PDF input is explicitly false.
4. Phase 1 must run controlled tasks through the managed OpenChamber route to
   establish actual CPA GUI effort behavior. Until then, route-name suffixes
   are labels only.

## Pre-Modification Checksums

These SHA-256 values were captured before any framework configuration change.
They identify files without including their secret-bearing contents.

| Path | Bytes | Modified UTC | SHA-256 |
|---|---:|---|---|
| `C:\Users\quang\.config\opencode\opencode.json` | 1,924 | `2026-08-02T02:53:52.8375321Z` | `996D99C52276CF1D82D9C63DA752A90CD5F59358DA641C6466832A5CD8FE08EF` |
| `C:\Users\quang\.config\opencode\opencode.jsonc` | 50 | `2026-07-24T15:08:28.1917343Z` | `4E901F9E457C8D52AB31F9FB4EA637A8C9104EBDBF23FE8B3600F35AD46D4A61` |
| `C:\Users\quang\.config\opencode\opencode.json.cpa-gui.state.json` | 100 | `2026-08-02T02:53:52.8375321Z` | `9E4713B5C596F0BD6A9CF4EBEF3A1FDD6B7CC307D11D38DC5883AB45B69A18AE` |
| `C:\Users\quang\.config\openchamber\settings.json` | 4,549 | `2026-08-02T02:54:24.6131811Z` | `44C611E30FC179E64C6DD042AB6E45E235F7F534225558CCAA65FAFFD3F5BB13` |
| `C:\Users\quang\.config\openchamber\managed-opencode\5084.json` | 241 | `2026-08-01T14:18:12.3496478Z` | `89C85BCCA079AC3B13F86A78CDD3DB0EC9C0718C63EAB63EEDF9B78A270CF31E` |
| `C:\Users\quang\.config\openchamber\agent-tool\openchamber-plugin.js` | 9,229 | `2026-08-01T14:18:11.0733859Z` | `17246D5DB4D3C6BDB2EDD98C53F084718BCD73ED27D0A57D5930EF9B292AE4ED` |

The `opencode.json` hash is recorded because the file is a potential future
configuration target. Its content contains an API-key field and must never be
copied into this workspace or quoted in reports.

## Secret and State Exclusions

Never copy any of the following into `D:\Projects\SDD`, Git, prompts, Context7
queries, or framework backups stored in the workspace:

- `C:\Users\quang\.config\opencode\opencode.json` and any future provider,
  auth, token, cookie, key, credential, or `.env` file;
- `C:\Users\quang\.config\openchamber\settings.json` and its temporary files;
- `client-pairing-sessions.json`, `remote-clients.json`, `relay-host.lock`,
  `sessions-directories.json`, and `goals\*`;
- `managed-opencode\*` runtime records and `agent-tool\*` runtime plugin files;
- Electron profile state in `C:\Users\quang\AppData\Roaming\OpenChamber`,
  including cookies, local/session storage, caches, logs, install IDs, and
  updater identifiers.

`settings.json` was structurally inspected without recording values. It holds
relay encryption/signing private JWK material, session-specific auto-accept
permission state, local project data, and UI state. It is excluded in full.

## Backup, Validation, and Rollback Procedure

Use this procedure only after a future phase identifies a supported write path
and a specific affected file. Do not back up OpenChamber-owned runtime/state
files. Store backups outside the framework workspace in the user-private local
data path.

1. Quit OpenChamber and CPA GUI before any persistent global config write.
2. Choose only the supported affected file. For the current CPA GUI-managed
   `opencode.json`, stop unless a CPA GUI-supported write mechanism has been
   established first.
3. In PowerShell, create a timestamped local backup and manifest:

```powershell
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = "C:\Users\quang\.local\share\opencode\framework-backups\$timestamp"
$target = 'C:\Users\quang\.config\opencode\opencode.jsonc'
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
Copy-Item -LiteralPath $target -Destination $backupRoot -Force
Get-FileHash -LiteralPath $target -Algorithm SHA256 |
  Format-List Path, Algorithm, Hash |
  Out-File -LiteralPath "$backupRoot\manifest-before.txt" -Encoding ascii
```

4. Apply one minimal change through the identified owner path and record the
   after-change SHA-256 in the same protected backup directory.
5. Validate using the managed OpenChamber binary:

```powershell
$managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe'
& $managed debug config
& $managed agent list
& $managed models cpa-gui --verbose
& $managed models minimax-coding-plan --verbose
```

6. If validation fails, restore only that file from its same-timestamp backup,
   then validate again:

```powershell
Copy-Item -LiteralPath "$backupRoot\opencode.jsonc" -Destination $target -Force
& $managed debug config
```

7. Restart OpenChamber and CPA GUI. The active process does not hot-reload
   persistent OpenCode configuration.

Do not use `git reset`, `git checkout`, bulk directory restores, or deletion as
a rollback mechanism. Preserve unrelated user edits and let OpenChamber
recreate its runtime files.

## Phase 1 Entry Conditions

Phase 1 may proceed only with these constraints:

- benchmark the bundled managed OpenCode `1.18.9` route;
- treat the CPA GUI `med`, `high`, and `xhigh` names as unverified labels until
  transport and task evidence establish their effective mapping;
- do not change `opencode.json` or its CPA GUI state sidecar directly;
- do not copy any OpenChamber settings, pairing, relay, goal, runtime, or
  Electron-profile data into this workspace;
- before any configuration write, record a supported owner path, protected
  backup location, before checksum, validation command, and file-level rollback.

## Evidence Commands Run

```powershell
opencode --version
opencode debug config
opencode models --verbose
opencode models cpa-gui --verbose
opencode models minimax-coding-plan --verbose
opencode agent list
& 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe' --version
Get-Process
Get-FileHash -Algorithm SHA256
```
