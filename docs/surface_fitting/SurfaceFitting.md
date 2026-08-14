# Surface Fitting

The official pipeline is Recognition Region → robust primitive fitter → residual validation → GeometryKernelAPI → OpenCascade face → Surface Repository. A fit never bypasses the kernel and an unsupported region never receives simulated geometry.
