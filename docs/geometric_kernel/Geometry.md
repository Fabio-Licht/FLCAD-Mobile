# Geometry

Immutable primitives include 2D/3D/4D vectors, matrices, quaternion, transform, coordinate systems, lines, rays, segments, planes, triangles, polygons, polyhedra and bounding volumes. Callers pass a `PrecisionContext` when comparing values; exact floating-point equality is not used as geometric equality.

Legacy `Vec3` and `BoundingBox` interoperate through `smart_regions_geometry_adapter.dart`, allowing staged migration without breaking public APIs.
