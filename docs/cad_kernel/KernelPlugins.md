# Kernel Plugins

`KernelPlugin` supplies metadata, compatibility state and a `GeometryKernelAPI` instance. `KernelPluginRegistry` rejects duplicate IDs and incompatible plugins before activation.

OpenCascade, Parasolid and a future FLCAD kernel must be implemented as plugins. Vendor libraries, native handles and conversion details stay behind the API boundary and are not part of this sprint.

