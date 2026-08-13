# Refactoring Plan

## R1 — Composition inversion (highest priority)

Create `app/bootstrap/platform_composition.dart`. Move strategic service registration out of `EngineeringContext.standard` while retaining that factory as a compatibility facade. Move FEL domain command aggregation behind command-contributor registration. Add dependency-cycle CI checks.

## R2 — Serialization governance

Create a schema catalog and migration registry. Wrap persisted roots in Engineering Envelope semantics. Separate entity revision from schema version. Add golden V0→V1 and unknown-version tests before changing stored models.

## R3 — Project repository consolidation

Declare `features/projects` canonical. Add adapters for Jobs and legacy Home projects, migrate active markers, then remove legacy implementations only in a major compatibility window.

## R4 — Runtime scheduler

Specify a common scheduler capability: task ID, priority, cancellation, concurrency, progress and metrics. Adapt existing runtimes one at a time, beginning with Knowledge/Cognition/Autonomous because their wrappers are structurally similar.

## R5 — Cache capabilities

Define optional capabilities (`read/write`, namespace, TTL, persistence, metrics, eviction) instead of one forced generic cache. Add bounds to replay/history stores and expose hit/size metrics.

## R6 — Geometry boundary

Introduce a kernel-owned mesh view interface and adapters for legacy `MeshTopology`. Migrate consumers incrementally; preserve Smart Regions public models.

## R7 — Product integration

Create one Project Workspace shell and bind Autonomous `ReconstructionUiState` to next-step, dependencies and explanations. Keep existing capture and reconstruction routes during migration.

## R8 — Quality gates

Add architecture dependency tests, serialization golden tests, profile benchmark jobs, long-session memory tests and corrupt-project recovery tests. Establish API deprecation and error-code policies.

Each refactoring must land independently with all existing tests passing and no persisted-data change without a migration.
