# Geometric Kernel Architecture

The Geometric Kernel Foundation is the dependency-free mathematical layer shared by Mobile, Desktop, Cloud and future CAD kernels. `GeometricKernelApi` is its facade and is registered in `EngineeringContext.standard`. Existing Smart Regions geometry remains source-compatible through explicit adapters.

Dependency direction is `features -> engineering domains -> geometric_kernel`; the kernel never imports a domain model except inside `adapters/`. GPU and Cloud implementations depend on contracts, not on the core. B-Rep, solids and Boolean operations are deliberately outside G-002.

Runtime flow: caller -> API/runtime -> precision context -> algorithm -> validation/metrics. Concrete algorithms never return invented geometry; unavailable cylinder, cone and free-surface fitting remain typed extension contracts.
