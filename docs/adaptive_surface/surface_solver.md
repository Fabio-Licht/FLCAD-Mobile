# Adaptive Surface Solver

`AdaptiveSurfaceSolver` executa builders elegíveis concorrentemente, isola falhas de candidatos e classifica os resultados por precisão, continuidade, estabilidade e simplicidade. Novos solvers entram por registro, sem alterar o engine.

`IsolateSurfaceRuntime` desloca o multi-solver para background. GPU e Cloud são contratos (`GPUSurfaceSolver`, `DistributedSurfaceSolver`) para CUDA, Metal, Vulkan e OpenCL, sem implementação nesta fase.
