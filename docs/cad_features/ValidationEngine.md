# Validation Engine

Production feature validation covers open wires, self-intersections, duplicated edges, non-manifold topology, invalid shells and solids, tiny edges, degenerated faces and inconsistent orientation.

Kernel messages are converted to portable diagnostics. Any error rolls back the transaction; warnings remain auditable on the feature.

