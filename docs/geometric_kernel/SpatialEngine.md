# Spatial Engine

`SpatialIndex` unifies nearest-neighbor, radius and range queries. `LinearSpatialIndex` is the exact baseline and current `KDTree` compatibility implementation. Octree, BVH, AABB tree and OBB tree are explicit interfaces for optimized backends. This keeps query semantics stable while preventing false performance claims.
