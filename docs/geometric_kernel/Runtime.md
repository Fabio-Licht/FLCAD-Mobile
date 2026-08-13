# Runtime

`GeometricKernelRuntime` records operation duration and success. `GeometricTaskScheduler` executes sendable computations in an isolate and checks cooperative cancellation before and after execution. `GeometricComputeBackend`, `GpuGeometricBackend`, `RemoteGeometricKernel` and `DistributedGeometryExecutor` prepare scheduling for CUDA, Vulkan, Metal, OpenCL, WebGPU and Cloud without binding the foundation to a vendor.
