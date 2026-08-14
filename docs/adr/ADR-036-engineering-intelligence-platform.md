# ADR-036 — Engineering Intelligence Platform

## Decision

Engineering Intelligence consumes immutable, project-local knowledge snapshots. Analysis is explicit and read-only. Recommendations are deterministic, explainable and consultative; accepting or rejecting one records history but never invokes a modeling API or geometry operation.

The platform may observe kernel health as evidence but never calls geometry creation or validation. Learning is limited to local recommendation decisions and observed outcomes and does not modify reasoning rules automatically.

## Consequences

Project score, health, diagnostics and strategies can combine evidence from Recognition, Reference, Alignment, Live Validation, Sketch and Feature systems without coupling their mutable implementations or surrendering user control.
