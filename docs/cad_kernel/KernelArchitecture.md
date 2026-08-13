# FLCAD CAD Kernel Foundation

The CAD kernel boundary is owned by `core/cad_kernel`. Application modules depend on `GeometryKernelAPI`, never on a vendor SDK. `KernelManager` selects a registered implementation, checks its health and exposes an explicit unavailable fallback when no kernel is active.

The foundation contains contracts and orchestration only. It does not create B-Rep entities, import STEP/IGES, execute booleans or emulate unsupported geometry.

## Dependency direction

`UI / Workflow / ERI / EDE / FEL -> KernelManager -> GeometryKernelAPI <- KernelPlugin`

Opaque `ShapeHandle` values cross this boundary. Vendor-native objects must remain inside the plugin. Runtime services are registered by `EngineeringBootstrap`, so Mobile and Desktop consume the same public contract.

## Extension points

- kernel plugins and capability negotiation;
- geometry and topology factory contracts;
- transaction, history and persistent identity services;
- topology graph, validation and healing contracts;
- runtime measurements and FEL commands.

