# Hybrid Topology Domain

O HTD implementa o Engineering Mesh Continuum: a geometria original é um `GeometryAssetRef` permanente e nunca é sobrescrita. `HybridObject` relaciona Mesh, Point Cloud, Voxel, Regions, References, Sketches, Surfaces e futuros Solids usando IDs e fingerprints portáveis.

Edições são deltas em `MeshLayer`. O engine não cria STL intermediário nem duplica buffers. Booleanos, B-Rep, CAM, CNC e simulações físicas permanecem fora do escopo.
