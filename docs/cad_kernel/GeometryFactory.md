# Geometry Factory Contracts

`GeometryFactories` exposes contracts for vertex, edge, wire, face, shell, solid and compound creation. Every request carries a project ID and active transaction, and produces an opaque `ShapeHandle` only through a supporting kernel.

The unavailable kernel throws `UnsupportedError`. These factories contain no geometric algorithms and are extension points for future plugins.

