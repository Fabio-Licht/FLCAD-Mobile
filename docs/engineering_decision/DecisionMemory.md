# Decision Memory

Accept, reject, defer, replace and modify operations produce immutable memory records and Engineering Learning events. Application bootstrap uses `ProjectDecisionMemoryStore`, persisted atomically under `Project/Decisions/decision-memory.json`. In-memory storage remains available for deterministic tests.
