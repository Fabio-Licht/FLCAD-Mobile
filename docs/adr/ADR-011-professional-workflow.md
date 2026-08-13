# ADR-011: Use an observable Project First workflow aggregate

Status: Accepted

## Decision

Create `ProfessionalWorkflowState` as the UI-independent read model and command target for the Ω Workspace. Flutter renders state and sends intent through `ProfessionalWorkflowController`. Existing AREI, Cognition and Autonomous Reconstruction remain specialist evidence/planning engines; Ω does not duplicate them.

## Consequences

Mobile can deliver a continuous workflow now, while Desktop and Cloud can reuse the same contracts. Real STL import and deeper engine adapters remain integration work; unavailable B-Rep, STEP and boolean execution is always explicit.
