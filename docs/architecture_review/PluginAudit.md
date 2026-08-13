# Plugin Audit

## Domains with explicit plugin infrastructure

- AI: provider plugin manager and capability selection.
- FEL: hot-register/unregister command plugins.
- AREI: inference plugin contract.
- Engineering DNA: knowledge and rule plugins.
- Engineering Cognition: cognition enrichment plugins.
- Autonomous Reconstruction: planner enrichment plugins.

## Domains without a general plugin contract

Geometric Kernel, Smart Regions, Reference Engine, Intelligent Sketch, Adaptive Surface, Hybrid Topology and Parametric Engineering expose several specialized interfaces, builders or GPU/Cloud contracts, but no consistent plugin lifecycle/manifest/capability contract.

## Findings

Plugin registries differ in duplicate handling, version semantics, unloading and capability discovery. There is no shared plugin identity, compatibility range, trust policy, permission model or failure isolation. A plugin can currently return domain objects, but there is no validation boundary that proves Project First ownership.

## Recommendation

Create a platform-level plugin descriptor and lifecycle contract in Engineering Core, then adapt existing managers without removing their public APIs. Require ID, semantic version, platform compatibility, capabilities, permissions, deterministic unload and validation. Do not add plugins during this audit.
