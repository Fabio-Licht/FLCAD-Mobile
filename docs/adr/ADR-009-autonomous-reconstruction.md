# ADR-009 — Autonomous Reconstruction

- Status: Accepted
- Context: Cognition can recommend individual elements but reconstruction requires dependency-aware sequencing.
- Problem: Out-of-order references, sketches and surfaces cause rework and invalid models.
- Alternatives: fixed pipeline; user-only planning; evidence-driven DAG and scheduler.
- Decision: Build an immutable, revisioned workflow with validated dependencies, risks, alternatives and timeline.
- Consequences: the system can advise and schedule but explicitly refuses CAD geometry execution in 0.9.0.
- Future impact: real executors must honor stage contracts, Project First transactions and human approval policy.
