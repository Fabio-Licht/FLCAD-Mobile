# ADR-045 — Professional Surface Patch & Topology Engine

## Status

Accepted.

## Decision

Surface topology is extracted only from native OpenCascade face handles. `TopoDS_Wire` and `TopoDS_Edge` provide loops, boundary closure and BRepGProp lengths; `BRepAlgoAPI_Section` provides real Surface×Surface intersection curves. The adapter exposes additive read-only topology contracts and keeps native tokens private.

Patch entities reference existing surface handles. They do not construct solids, shells or final BRep models. Freeform and rejected fits never enter the patch network. Project First persists the graph and all projections under `CAD/Topology*`.

Bootstrap registers only passive factories/repositories/runtimes. Native loading remains lazy on the explicit topology operation.
