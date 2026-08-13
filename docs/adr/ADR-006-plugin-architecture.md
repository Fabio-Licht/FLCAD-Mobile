# ADR-006 — Plugin Architecture

- Status: Accepted, partially implemented
- Context: Knowledge, AI and engineering algorithms must evolve without recompiling the platform core.
- Problem: Direct domain dependencies make extension and vendor integration expensive.
- Alternatives: forks; compile-time registries; capability-based plugins.
- Decision: Use domain plugin contracts and registries with explicit IDs and versions.
- Consequences: six domains support plugins; lifecycle, permissions and compatibility are not yet standardized.
- Future impact: establish a platform descriptor, trust policy and capability validation before third-party plugins.
