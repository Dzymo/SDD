## Context

The service needs an availability signal with no dependency on application data.

## Goals / Non-Goals

**Goals:**
- Return a deterministic availability response for a healthy service.

**Non-Goals:**
- Report dependency-level diagnostic details.

## Decisions

- Use one public HTTP endpoint because consumers already communicate over HTTP.

## Risks / Trade-offs

- [Endpoint reports only process availability] -> Document that it is not a deep dependency probe.
