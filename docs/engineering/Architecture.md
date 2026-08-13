# FLCAD Engineering Platform Architecture

Princípios: Project First, entidades referenciadas por ID, geometrias pesadas fora do JSON, comandos separados de queries, comunicação transversal via EPB e kernels atrás de adapters.

```mermaid
C4Context
  title FLCAD Platform Context
  Person(user, "Engineer")
  System(flcad, "FLCAD Engineering Platform")
  System_Ext(cloud, "FLCAD Cloud")
  System_Ext(kernel, "Geometry Kernel")
  Rel(user, flcad, "Engineering workflows")
  Rel(flcad, cloud, "Optional synchronization")
  Rel(flcad, kernel, "Adapter contract")
```

```mermaid
flowchart LR
  UI[Mobile/Desktop/Plugins] --> API[Domain APIs]
  API --> EPB[Engineering Platform Bus]
  EPB --> ENG[Engineering Context]
  ENG --> DOM[Regions/References/Sketch/Surface/Topology/PED]
  ENG --> INF[Runtime/Cache/History/Graph/Metrics]
  DOM --> K[Kernel Adapter]
```
