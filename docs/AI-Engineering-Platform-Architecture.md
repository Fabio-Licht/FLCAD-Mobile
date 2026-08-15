# AI Engineering Platform Architecture

## Purpose

The AI Engineering Platform is a deterministic, explainable and consultative architecture for interpreting engineering evidence and guiding CAD reconstruction. “AI” denotes explicit engineering reasoning: no Machine Learning, LLM, generative model or external context participates in a decision. Geometry and CAD commands remain under explicit user control.

## Architecture

The platform is a one-way pipeline whose outputs are immutable projections consumed by the next layer:

`AI Foundation → Primitive Intelligence → Engineering Features → Smart References → Reconstruction Strategy → Interactive Assistant → Engineering Knowledge`

Reverse imports are prohibited. Every layer records evidence, justification, origin, scores, discarded hypotheses and traceability. Project First repositories keep the resulting sessions beside the project. Logical sequences supplied by callers replace clocks, timers and background workers.

## AI Engineering Foundation

The foundation owns engineering context, snapshots, feature vectors, confidence composition, consultative advice, analytics and persistence. It defines the shared audit vocabulary and does not execute CAD operations.

## Primitive Intelligence

Primitive Intelligence converts recognized observations into ranked hypotheses for planes, cylinders, cones, spheres and tori. It also describes symmetry, repetition patterns and manufacturing relevance. Recognition is consumed through the official adapter; no parallel STL parser exists.

## Engineering Features

Feature Intelligence correlates primitives into engineering features. Its feature graph, confidence tree, Engineering DNA, relationships and dependencies preserve the evidence behind every hypothesis. Graph construction is deterministic and cycle-safe.

## Smart References

Smart References proposes canonical planes, axes, points, datums and coordinate systems. Ranking and alignment strategies are fully scored and explainable. A proposal is not a CAD entity and cannot modify geometry.

## Reconstruction Strategy

The strategy layer creates consultative playbooks and at least three reconstruction alternatives. Dependency graphs define ordering; difficulty and engineering reasoning explain priorities and risks. Steps can be accepted, edited or rejected and session revisions support rollback, but no command is executed.

## Interactive Assistant

The assistant presents the accumulated evidence as technical messages, progress, alerts, suggestions, comparisons and answers. Context awareness is limited to project state. Timelines use caller-provided logical ordering; snapshots are persistent and reversible.

## Engineering Knowledge

The knowledge layer records explicit user decisions in isolated profiles and a case library. Similarity uses published deterministic scoring, rules are editable and versioned, and every recommendation points to an existing case. Reuse creates a proposal requiring approval and never changes behavior automatically.

## Explainable engineering philosophy

An acceptable result is reproducible from the same inputs and answers five questions: what evidence participated, why the result was proposed, where it originated, how it scored, and which alternatives were discarded. Missing audit information is a certification failure, not a reason to invent a fallback.

## Certification boundary

G-012H adds no engineering capability. It audits the seven modules, their dependency graph, workspaces, property inspectors, persistence roots, analytics and ADR conformity. Performance certification uses deterministic capacity and serialized-size limits because internal timing is prohibited. The certification date and coverage statement are explicit inputs, making certificate generation reproducible.

## Evolution principles

Future changes must retain user approval, immutable evidence, versioned decisions, Project First persistence, acyclic dependencies and deterministic tests. Any new module must supply its own workspace, inspector, analytics, persistence contract, ADR and certification evidence before joining the official graph.
