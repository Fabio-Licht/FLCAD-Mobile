# Engineering Audit

## Responsibility chain

| Layer | Accepted responsibility | Audit result |
|---|---|---|
| Engineering Core | context, buses, history, cache, graph, services | coherent, but composition leaks upward |
| Geometric Kernel | mathematical and numerical foundation | appropriately independent except legacy adapters and Engineering API registration |
| AREI | observe, hypothesize, plan strategies | evidence-based; overlaps lightly with Cognition part/surface probabilities |
| Engineering DNA | ontology, rules, patterns and knowledge | clear knowledge boundary |
| Engineering Cognition | turn knowledge into practical recognition | correct role; reuses AREI/DNA |
| Autonomous Reconstruction | DAG planning and scheduling | correct role; rejects CAD execution |

## Repetition

Part and manufacturing classifications appear in AREI and are mapped again in Cognition. This is acceptable adaptation but should use shared taxonomy identifiers rather than string switches. Evidence, confidence and provenance models are separately declared in AREI, DNA, Cognition and Autonomous Reconstruction. Their semantics differ, yet a small shared provenance contract would reduce conversion code.

## Integration quality

Each strategic layer has an explicit Engineering Core integration that records history, graph nodes and events. Project IDs flow through snapshots and contexts. However, integrations are invoked manually; no transaction boundary guarantees that history, graph and event publication succeed atomically.

## Recommendation

Create shared taxonomy IDs and an `EvidenceView`/`ProvenanceView` contract. Keep domain-owned concrete models. Move registrations into the application bootstrap and add an orchestration transaction/outbox before Cloud synchronization.
