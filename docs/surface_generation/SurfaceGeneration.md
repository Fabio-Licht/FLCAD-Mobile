# Automatic Surface Generation

`core/surface_generation` converts approved analytical candidates from Surface Intelligence into real kernel requests. Plane, Cylinder, Cone and Sphere are supported in G-005B. Every geometry request passes exclusively through `GeometryKernelAPI`; no OpenCascade type enters the domain.

The mandatory pipeline is candidate validation, geometry builder, shape validation, healing proposals, registry, Engineering Graph, history and analytics. Registry and graph stages occur only after a real valid handle exists.

