# ADR-063 — Professional Engineering Knowledge Engine

## Status

Accepted.

## Context

Engineering decisions from recognition, Primitive Intelligence, Feature Intelligence, Smart References, Reconstruction Strategy and the Interactive Assistant must be reusable without machine learning, generative inference, hidden fallback behavior or automatic CAD execution.

## Decision

The system uses an explicit, project-first case library. Every `ProfessionalEngineeringCase` stores its origin, Engineering DNA signature, primitive and feature graphs, smart references, playbook, chosen strategy, user edits and final result. Knowledge profiles isolate domains such as stamping, deep drawing, plastics molds and aerospace.

Similarity is deterministic: the engine publishes Jaccard scores for DNA, features, topology, symmetry and relations, plus bounded complexity distance and exact strategy agreement. Their equal-weight mean is the reported percentage, with stable case-id tie breaking.

Decision Memory is an append-only versioned record of user decisions and justifications. Rules are editable objects whose edits create a new version; matching a rule only returns a consultive proposal and never changes runtime behavior. Strategy reuse produces an unapplied proposal requiring explicit approval. Every recommendation must point to an existing case and expose evidence.

State revisions support deterministic rollback. Persistence is rooted at the selected project under `CAD/EngineeringKnowledge`, `EngineeringCases`, `KnowledgeProfiles`, `KnowledgeRules`, `SimilarityDatabase`, and `StrategyHistory`. Analytics count explicit events and contain no clock or timer.

## Integration

The knowledge layer consumes stable projections from AI Engineering Foundation, Primitive Intelligence, Engineering Feature Intelligence, Smart References, Reconstruction Strategy, Interactive Assistant and Manufacturing. Those modules never import this layer, preserving an acyclic dependency direction.

## Consequences

Learning is transparent, reproducible and reversible. No ML, LLM, parser, isolate, worker, timer, geometry mutation or automatic command path exists. The legacy `EngineeringCase` remains intact; the richer case-library entity is named `ProfessionalEngineeringCase` to preserve API compatibility.
