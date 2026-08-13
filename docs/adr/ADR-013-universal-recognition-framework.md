# ADR-013: Centralize geometric recognition in URF

Status: Accepted

## Decision

New primitive recognition runs through `RecognitionApi` and `GeometricRecognitionEngine`. Individual recognizers are stateless plugins operating only on `RecognitionContext`. The engine owns concurrency, competition, confidence fusion, persistence, graph and decision integration.

## Consequences

Mobile, Desktop and Cloud can reuse identical recognition contracts. Existing Cognition recognizers remain compatible evidence consumers during migration. Unsupported primitives return no detection, and indeterminate observations produce `unknown`; the framework never fabricates geometry or CAD.
