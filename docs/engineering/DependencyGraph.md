# Dependency Audit

Static inventory on consolidation: 323 Dart files, 591 imports under `lib/core`, 18 test files. The canonical dependency direction is UI → Domain API → Engineering Core → infrastructure adapter.

No analyzer-detectable cycles or compile-time violations remain. Architectural duplication remains intentionally behind compatibility boundaries: legacy domain EventBus, Cache, History, DNA and Graph types still exist. Engines now accept an optional `EngineeringContext`; new integrations must not add direct cross-domain imports and should communicate through EPB/Knowledge Bus.

Highest coupling area: FEL native commands, because it adapts the language to every domain. It is treated as an edge adapter, not a domain dependency.
