# Surface Network e GSO

`SurfaceNetwork` mantém superfícies e constraints de continuidade. O modelo suporta G0–G4, curvature flow e energy minimization. `GlobalSurfaceOptimizer` atua sobre a rede inteira e redistribui continuidade iterativamente, preservando a separação entre geometria e estratégia.

O Alpha não modifica control points para prometer G2/G4 artificialmente. Solvers futuros podem consumir as mesmas constraints e devolver uma rede otimizada.
