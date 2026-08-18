# G-109 — OCCT 8.0.1 operator audit

Status: OFFICIAL IMPLEMENTATION GATE

The user-approved A/B/C classification in this document supersedes previous
audit wording.

This audit distinguishes an existing real OCCT mapping from a similarly named
operation. A command is not operational merely because it reaches the FFI.

| Command | Current bridge | Required official OCCT route | Audit status |
|---|---|---|---|
| Extend by length | `GeomLib::ExtendSurfByLength` | same, bounded non-periodic surface | Real, limited |
| Extend until geometry | absent | extend, intersect with target, then trim/rebuild face | Composition required |
| Trim by UV | `BRepBuilderAPI_MakeFace(surface,u1,u2,v1,v2)` | same | Real, parametric only |
| Trim by Curve/Surface/Plane/Boundary | absent | `BRepAlgoAPI_Splitter`/section plus face selection | Composition required |
| Offset | `BRepOffsetAPI_MakeOffsetShape::PerformByJoin` | same | Real |
| Offset + Walls/Close | absent | `BRepOffsetAPI_MakeThickSolid` or offset plus official topology builders/sewing | Missing bridge |
| Per-face/partial offset | absent | OCCT offset/thick-solid face selection where applicable | Missing bridge |
| Match G0/G1/G2 | incorrectly routed to `BRepOffsetAPI_MakeFilling` | `GeomPlate_CurveConstraint` + `GeomPlate_BuildPlateSurface` and approximation/retrim | Not implemented |
| Blend between faces | incorrectly routed to filling | `BRepFilletAPI_MakeFillet` for edges of a common shell/solid | Not implemented |
| Fair Surface | absent | no general OCCT 8.0.1 surface-fair operator | Category C: proprietary FLCAD algorithm |
| Morph Surface | absent | no general OCCT 8.0.1 surface-morph operator | Category C: proprietary FLCAD algorithm |
| Replace Boundary | absent | rebuild constrained surface and face topology | Not implemented |
| Replace Surface/Face | absent | `ShapeBuild_ReShape` with validated replacement and resewing | Missing bridge |
| Delete Face | absent | `ShapeBuild_ReShape::Remove` followed by topology validation | Missing bridge |
| Heal | `ShapeFix_Shape::Perform` | local tools require narrower `ShapeFix_*` contracts | Real, global only |
| Validate | partial quality sampling | `BRepCheck_Analyzer`, topology traversal and tolerances | Incomplete |
| Sew | `BRepBuilderAPI_Sewing` | same | Real |
| Unsew | absent | extract/rebuild selected faces as independent topology; OCCT has no single Unsew algorithm | Composition required |
| Merge Faces | absent | `ShapeUpgrade_UnifySameDomain` | Missing bridge |
| Split Face | `BRepAlgoAPI_Splitter` exists | expose face/tool workflow | Kernel real, UI missing |
| Boundary extraction | returns compound of Edges | materialize official Boundary/Edge/Wire entities | Partial |
| Zebra/Reflection | CPU-derived scalar summaries only | viewport visualization needs shader/display implementation using kernel data | Not visual analysis |
| Curvature/Gaussian/Draft | sampled with `GeomLProp_SLProps` | retain and expose fields/diagnostics | Kernel real, UI incomplete |
| G0/G1/G2 validation | absent as pairwise face analysis | `LocalAnalysis_SurfaceContinuity` and topology adjacency | Missing bridge |

## Mandatory corrections before UI exposure

1. Remove `BLEND` and `MATCH` from the filling branch. Returning a filling face
   under those operation names is semantically incorrect.
2. Define exact input topology for every operation (Face, shared Edge, Wire,
   Boundary, target Shape) and reject incompatible selections before native
   execution.
3. Every result must be a kernel-owned `ShapeHandle`, persisted before the
   `CadDocument` mutation.
4. Preview uses transient shapes. Apply replaces or inserts only the affected
   document entities and topology. Cancel destroys the transient result.
5. Fair and Morph are Category C. Their future proprietary algorithms require
   explicit numerical specifications and certification; no approximation may
   be presented under those names.

## Official A/B/C classification

- Category A: Extend, Offset, Trim, Split, Sew, Heal, Merge Faces, Validate.
- Category B: Match, Blend, Offset + Walls, Boundary Extend, Boundary Trim.
- Category C: Fair, Morph.

## Answers to the open questions

### Blend

OCCT contains a complete high-level operator for fillets along edges belonging
to a common Shell or Solid: `BRepFilletAPI_MakeFillet`. This is sufficient for
the shared-topology blend subset, with radius/law and internal C0/C1/C2
continuity controls. Arbitrary blends between disconnected Faces, Surfaces or
Boundaries do not have one complete public high-level operator. Lower-level
`ChFi3d`/`BRepBlend` algorithms exist but require the FLCAD composition to build
guides, walking solutions, approximated blend faces, trims and topology.
Therefore Blend is Category B. Proprietary geometric supplementation is not
authorized until the official composition is implemented and its remaining gap
is demonstrated.

### Match

`GeomPlate_CurveConstraint` is the official constraint:

- order 0: G0, controlled by distance tolerance or `SetG0Criterion`;
- order 1: G1, requiring a curve-on-support-surface and controlled by angular
  tolerance or `SetG1Criterion`;
- order 2: G2, requiring surface differential properties and controlled by
  curvature tolerance or `SetG2Criterion`.

Constraints are solved by `GeomPlate_BuildPlateSurface`; the result must be
approximated with `GeomPlate_MakeApprox`, retrimmed to the official Wire, made a
Face and validated. Match is Category B.

### Fair and Morph

`GeomPlate` and `Plate_Plate` are deformation foundations, not complete general
Fair or Morph commands. They do not define the product semantics for energy,
boundary preservation, local influence, convergence, topology rebuilding or
quality acceptance. No sufficient general official composition was identified.
Both operations remain Category C and require approved FLCAD specifications
before implementation.

### Offset + Walls

For a suitable closed shell/solid, prefer
`BRepOffsetAPI_MakeThickSolid::MakeThickSolidByJoin`, supplying the selected
opening faces and letting OCCT construct the offset and connecting walls. For an
isolated Face or open Shell, use `BRepOffsetAPI_MakeOffsetShape`, identify source
and offset boundary correspondence, construct each selected wall with official
Edge/Wire/Face builders, then `BRepBuilderAPI_Sewing`. `Offset + Close` adds
closing Faces and validates the resulting Shell. Every intermediate stays
kernel-owned; only the accepted final ShapeHandle is persisted.

## Geometry Input Resolver persistence rule

Automatic Sketch/Curve/Section adaptation may create transient Edge/Wire
shapes inside the active kernel transaction. Those conversions are not inserted
as additional CadDocument entities merely to execute a command. Only an entity
explicitly created by the operator and the final accepted operation result are
persisted. Existing official Curve/Edge/Wire entities are reused directly.

## Certification boundary

Static analysis, unit tests and successful FFI calls are supporting evidence,
not certification. Each visible G-109 command must complete Preview, Apply,
CadDocument update, topology projection, save/reopen and visual verification in
the Windows Release executable.
