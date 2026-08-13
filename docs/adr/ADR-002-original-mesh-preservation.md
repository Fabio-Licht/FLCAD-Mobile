# ADR-002 — Original Mesh Preservation

- Status: Accepted
- Context: Reverse-engineering edits must remain auditable and reversible.
- Problem: Direct mesh mutation destroys scan evidence and weakens undo.
- Alternatives: destructive edits with backups; full copies per edit; immutable source plus layers.
- Decision: Preserve the original mesh and represent changes as selections, deltas, layers and recipes.
- Consequences: algorithms need composition steps; storage is more compact than full copies and history remains explainable.
- Future impact: CAD/kernel adapters must never overwrite source geometry.
