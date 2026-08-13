# Plugin Lifecycle

1. The composition root creates `KernelManager`.
2. `OpenCascadeKernelPlugin` registers its adapter.
3. Selection initializes the native bridge and obtains the OCCT version.
4. A health check reads native diagnostics before activation.
5. Runtime queues operations locally because native handles are isolate-bound.
6. Unload shuts down the bridge and invalidates all private token mappings.

Failed selection preserves the previously active kernel. `selectWithFallback` can select an explicit alternate implementation.

