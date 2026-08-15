# ADR-062 — Professional Interactive Engineering Assistant

## Status

Accepted for Sprint G-012F.

## Decision

The Interactive Engineering Assistant is a deterministic, evidence-bound
presentation and guidance layer over the AI Engineering chain. It consumes only
the active project snapshots. It has no external context, language model,
generative provider, command executor or geometry mutation capability.

## Context and conversation

`ContextAwarenessEngine` consolidates loaded part, Primitive and Feature counts,
Smart References, active Playbook/strategy/step, session history and project
objectives. Engineering Conversation emits typed analysis, suggestion,
observation and answer records. Questions are a closed technical vocabulary;
every answer cites Feature, Reference and Strategy evidence.

## Timeline, progress and snapshots

Timeline ordering uses deterministic sequence numbers as logical time. No wall
clock is read internally. Progress is projected from explicit step approvals
and never executes a Playbook step.

Every state-changing user action produces a complete persisted snapshot with
context, Playbook, references, strategies, timeline and analytics. Repository
versioning enables integral rollback to a snapshot sequence.

## Guidance and explainability

Alerts and suggestions derive from unused references, absent coordinate-system
candidates, alternative strategies, dependency-scheduled next steps and
critical-region analysis. Side-by-side comparisons expose precision, estimated
time, complexity and confidence. Suggestions always retain technical evidence,
require explicit approval and record `executed=false`.

## Integration and persistence

Dependency direction is AI Engineering Foundation → Primitive Intelligence →
Engineering Feature Intelligence → Smart Reference System → Reconstruction
Strategy AI → Interactive Engineering Assistant → Manufacturing/Live
Reconstruction. Only immutable snapshots and IDs cross boundaries.

Project First persistence uses `CAD/InteractiveAssistant`,
`EngineeringTimeline`, `SessionSnapshots`, `EngineeringAlerts`,
`EngineeringSuggestions`, and `EngineeringContext`. There are no timers,
isolates, workers, fallbacks, STL parsers, ML, LLMs or generative AI.
