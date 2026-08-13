# Package Contract

> Agent-maintained project-local contract. The agent inspects project tooling,
> interviews the user only for unresolved release facts, and records the chosen
> commands here before packaging. Do not ask the user to fill it manually or
> copy example commands from another project.

## Delivery

- Intended version:
- Release type / prerelease Boolean:
- Immutable target SHA or source revision:
- Promotion relationship to any accepted RC:
- Package/build command:
- Expected artifact path or runtime entry point:
- Version inspection command:

## Clean Environment Smoke

- Temporary-environment setup command:
- Install or run command:
- Minimal smoke command:
- Expected observable result:

## Delivered Content Checks

- Development-only files that must be absent:
- Sensitive file-name and content checks:
- SHA-256 command and record location:

## Release And Rollback

- Exact external action (only after explicit user approval):
- Target/environment:
- Post-release smoke command:
- Project-specific rollback command or restoration steps:
- Conditions that block archive:
