# OpenCascade Adapter

`OpenCascadeKernelAdapter` is the only route from FLCAD kernel contracts to the native OCCT host. Native shape tokens are stored in a private map and converted to opaque `ShapeHandle` values containing only persistent identity, logical type, fingerprint and portable metadata.

The adapter routes import, export, validation, healing proposals, sewing and meshing through `OpenCascadeNativeBridge`. Unsupported modeling operations fail explicitly because they are outside G-004B.

The repository does not bundle an OCCT SDK or native host binary. Until one is installed and supplied to the plugin, `UnavailableOpenCascadeBridge` reports the kernel as unavailable; it never fabricates geometry.

