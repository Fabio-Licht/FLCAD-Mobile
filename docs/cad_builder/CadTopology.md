# CAD Topology

The project topology graph preserves the dependency sequence:

`Vertex -> Edge -> Wire -> Face -> Shell -> Solid`

Nodes reference persistent `ShapeHandle` IDs. Edges carry build relationships and reject missing nodes, reverse hierarchy and cycles. Portable graph snapshots are stored under `CAD/Topology/geometry_graph.json`.

