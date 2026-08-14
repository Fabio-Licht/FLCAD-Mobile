# Surface Operations Pipeline

The transactional sequence is User → SurfaceOperation → Constraint Solver → Topology Graph → Continuity Engine → Validation → GeometryKernelAPI → OpenCascade → Patch Update → Analytics → Project First. Only a validated commit may ask the kernel to create a replacement surface. The source patch is never edited in place.
