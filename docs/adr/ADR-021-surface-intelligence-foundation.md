# ADR-021: Surface Intelligence Foundation

- Status: Accepted
- Date: 2026-08-13

## Context

FLCAD must decide which surfaces belong to each region before attempting CAD construction. Existing recognition and engineering modules already produce evidence, while Adaptive Surface contains geometry-oriented capabilities that must not be invoked in this planning sprint.

## Decision

Create a separate `surface_intelligence` domain for evidence adaptation, candidate classification, boundary analysis, continuity prediction, strategy comparison, dependency graph, templates and explanations. Persist complete portable plans under project-owned planning directories.

Keep CAD Builder, Feature Engine and Adaptive Surface builders downstream. The planning engine imports only shared descriptive enums and continuity levels; it does not produce surface geometry or kernel handles.

## Consequences

- every proposed surface is evidence-based, scored and explainable;
- plans remain portable across Mobile, Desktop, Cloud and future kernels;
- Studio and FEL can inspect planning state without executing CAD;
- no NURBS, analytical surface, patch, blend, trim, healing or B-Rep capability is implied;
- later construction sprints must explicitly translate accepted plan candidates into kernel operations.

