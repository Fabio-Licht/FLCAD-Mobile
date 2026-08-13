# KernelManager

`KernelManager` owns registration, selection, health checks, version/capability discovery, unloading and fallback. Selecting a kernel performs a health check before activation. Removing or unloading the active kernel returns the manager to `UnavailableGeometryKernel`.

Consumers must query capabilities before requesting operations. An absent capability is a supported architectural state, not permission to simulate a result.

