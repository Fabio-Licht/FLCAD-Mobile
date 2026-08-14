# ADR-028 — Profile Recognition & Sketch Intelligence

## Status

Accepted.

## Decision

Profile recognition is a new `profile_recognition` domain that reads parametric Sketch entities and produces logical profiles, loops, regions, topology, validation, intent, quality, advice, and feature-readiness indicators. Its six graphs remain independent of `EngineeringGraph`.

Recognition never creates OpenCascade geometry, BRep, NURBS, surfaces, or CAD features. Readiness labels are advisory evidence only. CoPilot suggestions never execute actions. Runtime and persistence remain explicit and project-first.

## Consequences

Sketches can be validated and prepared for later feature modeling while preserving user control and kernel independence.
