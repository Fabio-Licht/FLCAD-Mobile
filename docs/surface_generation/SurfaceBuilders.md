# Surface Builders

Typed builders collect explicit parameters:

- Plane: origin, normal and bounds;
- Cylinder: axis origin, axis direction, radius and bounds;
- Cone: apex, axis direction, semi-angle and bounds;
- Sphere: center, radius and bounds.

Builders delegate to `SurfaceGenerationEngine`; they contain no geometric algorithms.

