# Geometry Graph

`GeometryGraph` stores opaque shape nodes and directed topology relationships. It validates entity existence and the allowed hierarchy:

`Vertex -> Edge -> Wire -> Face -> Shell -> Solid`

Compound relationships and semantic edge labels remain representable without leaking native topology. The graph is metadata infrastructure, not a B-Rep implementation.

