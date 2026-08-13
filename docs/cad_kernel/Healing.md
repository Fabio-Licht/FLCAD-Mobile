# Healing

Healing is advisory in G-004B. OCCT diagnostics may produce auditable `HealingProposal` objects for shape, wire and face repair. A proposal contains its reason and originating diagnostics.

No proposal mutates the source shape automatically. Applying fixes is intentionally outside this sprint.

`ShapeFix_Shape` operates on a copy solely to determine whether a correction can be proposed.
