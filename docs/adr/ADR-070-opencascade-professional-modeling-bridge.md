# ADR-070 — OpenCascade professional modeling bridge

## Decision

Professional surface geometry is executed only by OCCT 8.0.1 through
`flcad_occ_surface_operation`. Dart transports opaque native tokens and numeric
parameters; it does not calculate or fabricate geometry. Every successful call
stores the returned `TopoDS_Shape` and becomes a `ShapeHandle` in the adapter.

The existing `SurfaceOperationKernelAPI` remains source compatible. Redo is
exposed by the additive `ReversibleSurfaceOperationKernelAPI` contract.
Native persistence uses the additive `PersistentGeometryKernelAPI`, writing and
reloading OCCT BREP payloads while preserving the persistent shape identity.

## Native mappings

| Operation | OCCT 8.0.1 implementation | Result / parameters |
|---|---|---|
| Loft | `BRepOffsetAPI_ThruSections` | section wires; tolerance; shape |
| Sweep | `BRepOffsetAPI_MakePipe` | profile wire and spine wire; shape |
| Fill / Patch | `BRepOffsetAPI_MakeFilling` | boundary edges and approximation tolerances; face |
| Blend / Match | `BRepOffsetAPI_MakeFilling` | constrained boundary edges; face; limited to filling semantics |
| NURBS conversion | `BRepBuilderAPI_NurbsConvert` | source shape; converted shape |
| Extend | `GeomLib::ExtendSurfByLength` | length, C1/C2/C3, U/V side and before/after; face |
| Reduce | `ShapeCustom_BSplineRestriction` + `BRepTools_Modifier` | tolerances, maximum degree/segments; shape |
| Offset | `BRepOffsetAPI_MakeOffsetShape::PerformByJoin` | distance and tolerance; shape |
| Trim | `BRepBuilderAPI_MakeFace` | U/V bounds and tolerance; face |
| Split | `BRepAlgoAPI_Splitter` | argument and tool shapes; compound/shape |
| Join / Sew | `BRepBuilderAPI_Sewing` | shapes and tolerance; sewed shape |
| Heal | `ShapeFix_Shape` | source shape; corrected shape |
| Boundary | `TopExp_Explorer` + `BRep_Builder` | source edges; compound |

All inputs are checked for required token count and numeric parameters. OCCT
completion status and null results are checked before registration. Existing
`BRepCheck_Analyzer` validation remains available through `GeometryKernelAPI`.

## Confirmed limitations

- **Fair:** OCCT 8.0.1 provides the `FairCurve` package for curves. It has no
  general B-spline surface fairing operator.
- **Morph:** OCCT 8.0.1 has no general-purpose surface morph operator.
- **Blend / Match:** OCCT has specialized fillet and filling algorithms, but no
  single arbitrary two-surface G0/G1/G2 match operator. The exposed mapping is
  boundary-constrained filling and is therefore explicitly limited.

Undo and redo switch immutable native result history in the adapter; they never
construct replacement geometry. Project persistence continues to serialize
`ShapeHandle` metadata and operation definitions in the existing repositories.
