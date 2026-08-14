# ADR-037 — Professional Reverse Engineering Workflow

## Decision

The `reverse_workflow` domain orchestrates existing modules through persistent IDs, explicit state transitions and recorded results. It never reimplements domain engines or automatically executes CAD, validation or intelligence recommendations.

Twelve official steps use a guarded state machine. Snapshots, restore, replay and undo/redo operate on workflow state only. External module results are supplied explicitly by the user-facing operation and captured in the timeline.

## Consequences

The complete reverse-engineering journey becomes continuous, inspectable and resumable while each domain retains ownership of its data and side effects. Kernel and project operations remain subject to their existing explicit contracts.
