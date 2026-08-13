# CAD Builder

`core/cad_builder` is the Project First orchestration layer for the first B-Rep entities. `CadBuilderApi` exposes typed builders; `CadBuilderEngine` owns transactions, validation, graph updates, persistence, history and analytics.

All creation passes through `GeometryKernelAPI.create`. The domain contains no OpenCascade type and refuses to operate without a healthy selected kernel. The composition root exposes a project-scoped `CadBuilderFactory` to Engineering Core, Workflow, Decision, Reconstruction and Studio consumers.

G-004C includes only Vertex, Edge, Wire, Face, Shell and Solid. It does not include parametric features or modeling operations.

