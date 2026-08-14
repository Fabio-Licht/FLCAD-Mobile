# Mesh Import

`MeshApi.importStl` validates the real file, calls `MeshGeometryKernelAPI`, which lazily initializes OpenCascade and invokes `RWStl::ReadFile`. No alternate parser or BREP fallback exists.
