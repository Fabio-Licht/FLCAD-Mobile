# Linear Algebra

The unified `LinearAlgebra` API implements pivoted Gaussian solving, normal-equation least squares, weighted least squares, Cholesky, pivoted LU, modified Gram-Schmidt QR, Jacobi symmetric eigen decomposition, PCA and an SVD derived from the symmetric eigensystem of A-transpose-A.

These implementations prioritize deterministic, dependency-free behavior. Large or ill-conditioned production workloads can be routed through a future compute backend without changing domain APIs.
