# AR-001 Architecture Review 1.0

## Executive conclusion

FLCAD Mobile has a coherent domain vision and a working Project First vertical slice, but it is not yet ready to be labeled Professional 1.0. The repository contains 17 `core` modules, 382 Dart files under `core` (approximately 23,984 lines), and 133 passing tests before this audit. The strongest assets are explicit domain boundaries, immutable planning models, explainable evidence chains, non-destructive topology operations, and a complete project workspace.

The principal architectural issue is dependency direction. `EngineeringContext.standard` imports and constructs six higher-level domains, while those domains import Engineering Core integrations. FEL also imports every domain command package while several domains import FEL contracts. These composition decisions create compile-time module cycles even though runtime behavior remains deterministic.

## Findings by severity

### High

1. Composition roots are inside `core/engineering` and `core/fel`. This creates cycles: Engineering ↔ Geometric Kernel, AREI, Engineering DNA, Engineering Cognition and Autonomous Reconstruction; FEL ↔ most engineering domains.
2. Serialization is inconsistent. New foundations use schema/version envelopes, while Smart Regions has no schema version and Reference, Sketch and Surface use entity revision as though it were a serialization schema. No migration registry exists.
3. Persistence has three project implementations (`features/projects`, `features/home/projects`, and `features/jobs`) plus legacy active-job compatibility. This is the clearest duplicated product responsibility.
4. No profiled startup, heap, long-session or large-mesh benchmark exists. Passing functional tests is not evidence of production memory bounds.

### Medium

1. Twelve isolate runtimes duplicate cancellation and scheduling patterns with incompatible contracts.
2. Thirteen caches expose unrelated APIs and only `EngineeringCache` provides namespaces, TTL and metrics.
3. Plugin support is present in AI, FEL, AREI, Engineering DNA, Cognition and Autonomous Reconstruction, but absent from several geometry domains.
4. Large classes exceed 300 lines in constraint solving, capture UI and adaptive-surface orchestration.
5. The UI exposes capture and Alpha reconstruction but does not expose the new knowledge/cognition/autonomous workflow.

## Preserved strengths

- Project storage uses bounded project directories and atomic temporary-file replacement for key JSON files.
- The original mesh is treated as input; Hybrid Topology composes non-destructive layers.
- AREI, Engineering DNA, Cognition and Autonomous Reconstruction carry confidence, evidence and explanations.
- CAD stages are explicit plans and reject unsupported execution.
- `dart analyze lib test` reports no issues, and the complete test suite passes.

## Recommended boundary

Move platform composition to `lib/app/bootstrap/` in a compatibility-preserving release. Engineering Core should expose contracts only; the app composition root should register Geometric Kernel, AREI, DNA, Cognition and Autonomous Reconstruction. Apply the same inversion to FEL through command-contributor plugins.
