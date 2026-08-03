## Why

Consumers need a lightweight way to determine whether the service is available.

## What Changes

- Add a public status endpoint that reports service availability.

## Capabilities

### New Capabilities

- `status-endpoint`: A public endpoint reports whether the service is available.

### Modified Capabilities

<!-- No existing requirement changes. -->

## Impact

- HTTP routing and the service health-check test suite.
