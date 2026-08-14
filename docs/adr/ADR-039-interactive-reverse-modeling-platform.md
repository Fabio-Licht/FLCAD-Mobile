# ADR-039 — Interactive Reverse Modeling Platform

## Status

Accepted.

## Decision

Interactive selection consumes recognized evidence and produces previews, contextual suggestions and pending interaction intents. It never creates geometry. Accepting an intent records the user's decision and exposes the official command to the caller; execution remains the responsibility of Workflow → Reference Geometry → GeometryKernelAPI → adapter → OpenCascade.

Bootstrap registers passive services only. Runtime initialization is explicit. Project state is persisted under `CAD/Selections`, `CAD/SelectionHistory`, `CAD/SelectionAnalytics`, `CAD/SelectionPreview`, `CAD/InteractiveWorkspace` and `CAD/ContextActions`.

## Consequences

Selection remains deterministic and testable without a native backend. Recommendations are explainable and cannot mutate the model automatically. Existing domain APIs and lazy-loading boundaries remain intact.
