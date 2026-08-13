# ADR-010: Consolidate platform infrastructure behind compatibility facades

Status: Accepted

## Decision

Use `app/bootstrap` as composition root and consolidate scheduling, cache,
serialization, repositories and plugins under Engineering Core contracts. Existing
public domain runtimes and project descriptors remain compatibility facades during
incremental migration.

## Consequences

Cross-domain construction no longer needs to expand inside application widgets.
Infrastructure policy becomes measurable and testable. Temporary adapters remain
until persisted fixtures and real-device regressions prove safe removal; this debt
is explicit and must not become a second permanent implementation.
