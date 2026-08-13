# ADR-001 — Project First

- Status: Accepted
- Context: Images, meshes, knowledge and derived artifacts require stable ownership for Mobile/Desktop/Cloud synchronization.
- Problem: Loose files create orphaned data and ambiguous lifecycle.
- Alternatives: global asset library; user-managed folders; project-owned workspace.
- Decision: Every engineering artifact belongs to one Project and is stored or referenced inside its workspace.
- Consequences: deletion and synchronization operate at project scope; cross-project reuse needs explicit references.
- Future impact: Cloud tenancy and collaboration must preserve project IDs and ownership boundaries.
