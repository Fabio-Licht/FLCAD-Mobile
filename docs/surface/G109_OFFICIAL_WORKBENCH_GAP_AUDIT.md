# G-109 — Official Workbench Gap Audit

Status: AUDIT COMPLETE — IMPLEMENTATION NOT STARTED BY THIS REVIEW  
Date: 2026-08-17  
Reference: `G109_OCCT_AUDIT.md`, `G109_CATEGORY_B_OCCT_AUDIT.md`,
`G109_CATEGORY_B_DESIGN_REVIEW.md`, and the official G-109 workbench
specification received on 2026-08-17.

## Scope and freeze preservation

This review does not change `CadRuntime`, `CadDocument`, the Geometry Input
Resolver, `ShapeHandle`, transient materialization, persistence, or any product
code. Category A remains in Feature Freeze and QA. Category C remains blocked.

The latest official specification is broader than the previously frozen
Category B Design Review. Requirements that change selection order, modes,
preview semantics, or Apply results require a Design Review addendum before
implementation. They must not be silently folded into the frozen flow.

## Current implementation inventory

| Capability | Existing product route | Current status against the official workbench |
|---|---|---|
| Extend by length | `ProfessionalSurfaceTool.extend` → `GeomLib::ExtendSurfByLength` | Implemented, bounded-surface limitations apply |
| Trim by UV | `ProfessionalSurfaceTool.trim` → `BRepBuilderAPI_MakeFace` | Implemented; not the complete boundary/tool workflow |
| Offset | `ProfessionalSurfaceTool.offset` → `BRepOffsetAPI_MakeOffsetShape::PerformByJoin` | Implemented as a new offset shape |
| Heal global | `ProfessionalSurfaceTool.heal` → `ShapeFix_Shape::Perform` | Implemented; local heal is absent |
| Merge Faces | `ProfessionalSurfaceTool.mergeFaces` → `ShapeUpgrade_UnifySameDomain` | Implemented |
| Split | `ProfessionalSurfaceTool.split` → `BRepAlgoAPI_Splitter` | Kernel route implemented; dedicated Split Face UX is incomplete |
| Sew | `ProfessionalSurfaceTool.join` → `BRepBuilderAPI_Sewing` | Implemented |
| Validate | `flcad_occ_validate` → `BRepCheck_Analyzer` plus adjacency/tolerance diagnostics | Implemented baseline report; detailed gap metrics remain limited |
| Match | `ProfessionalSurfaceTool.match` → `GeomPlate_CurveConstraint`, `GeomPlate_BuildPlateSurface`, `GeomPlate_MakeApprox` | Category B route implemented; Release certification pending |
| Blend | `ProfessionalSurfaceTool.blend` → `BRepFilletAPI_MakeFillet` | Shared-edge route implemented; disconnected official composition is not implemented |
| Offset + Walls | `ProfessionalSurfaceTool.offsetWalls` → `BRepOffsetAPI_MakeThickSolid::MakeThickSolidByJoin` | One thick-solid route implemented; expanded four-mode contract is incomplete |
| Boundary Extend | `ProfessionalSurfaceTool.boundaryExtend` → `GeomLib::ExtendSurfByLength`, optional `BRepAlgoAPI_Splitter` | Implemented subset; explicit target kinds and deterministic retained domain need certification |
| Boundary Trim | `ProfessionalSurfaceTool.boundaryTrim` → `BRepAlgoAPI_Splitter` | Implemented subset; retained region is currently index-based, not viewport keep-point based |
| Surface quality sampling | `flcad_occ_surface_quality` → `GeomLProp_SLProps` | Numeric sampling exists |
| Zebra/Reflection | Numeric scores derived by the native inspector | No professional viewport visualization |
| Curvature/Gaussian/Draft | Native sampled values | Kernel data exists; interactive viewport analysis is incomplete |
| Fair/Morph | Explicit native technical failure | Category C, blocked as required |

## Category A audit

Category A remains frozen. No code change is authorized by this document.

| Command | Audit result | Remaining certification concern |
|---|---|---|
| Extend | Operational subset | Release Preview/Apply/Cancel and persistence smoke |
| Trim | Operational UV subset | General Curve/Surface/Plane trim belongs to Boundary Trim |
| Offset | Operational | Result classification and Release smoke |
| Heal | Global operational | Local Heal is a separate missing topology command |
| Merge Faces | Operational | Release topology/history verification |
| Split | Kernel operational | Dedicated Face selection/retained-fragment UX |
| Sew | Operational | Release open-edge/tolerance report verification |
| Validate | Operational baseline | Exact gap-size computation is not yet exposed |

## Category B audit

### Match Surface

The official OCCT route is present. G0/G1/G2 parameters reach `GeomPlate` and
the result is approximated to a BSpline Face. The implementation still needs
Release certification for measured continuity, topology reconstruction,
Preview/Apply/Cancel, Undo/Redo, and persistence. It must never fall back to
Filling; no such fallback is present in the current native branch.

### Blend Surface

The shared-topology route through `BRepFilletAPI_MakeFillet` is present. The
official specification also permits a composition for disconnected supports.
That composition is absent. The product must report that exact limitation; it
must not label Filling as Blend.

### Offset / Replace / Offset + Walls / Offset + Close

Only the `Offset` and one `Offset + Walls` thick-solid route exist. The official
four-mode behavior is not implemented:

- `Replace` has no explicit command or document replacement policy in the tool;
- `Offset + Close` has no separate mode/result contract;
- inside/outside is represented only by signed distance, with no bilateral mode;
- selected openings are passed as Faces to `MakeThickSolidByJoin`;
- the required per-Boundary choice (`create wall` or `leave open`) is absent;
- isolated Face/open Shell wall construction and sewing are not implemented.

This is a functional and UX expansion over the approved Category B Design
Review and requires a Design Review addendum before code changes.

### Boundary Extend

The current route extends a bounded surface and optionally splits it with target
shapes. The official modes Surface/Plane/Curve need explicit input validation,
deterministic target intersection and retained-domain selection. The current
implementation selects the first returned Face after splitting, which is not a
professional deterministic keep policy.

### Boundary Trim

The splitter route exists for Curve/Surface/Plane shapes. The current retained
Face is selected by numeric enumeration index. The approved Design Review
requires a viewport keep-point and geometric classification. Therefore the
native operator exists but the operator workflow is incomplete.

## Topology Workbench audit

| Tool | OCCT route | Product state | Required next gate |
|---|---|---|---|
| Sew | `BRepBuilderAPI_Sewing` | Present | Category A QA only |
| Unsew Face | extract selected Face and rebuild independent topology | Absent | Design Review + official composition |
| Unsew Selected | extract selected Faces preserving their geometry | Absent | Design Review + official composition |
| Unsew All | explode Shell into independent Faces | Absent | Design Review + official composition |
| Replace Face | `ShapeBuild_ReShape::Replace`, validate, resew | Absent | Audit route already identified; Design Review required |
| Delete Face | `ShapeBuild_ReShape::Remove`, validate result | Absent | Audit route already identified; Design Review required |
| Merge Faces | `ShapeUpgrade_UnifySameDomain` | Present | Category A QA only |
| Split Face | `BRepAlgoAPI_Splitter` | Kernel route present | Dedicated UX/fragment policy required |
| Heal Local | narrower `ShapeFix_Face`, `ShapeFix_Wire`, `ShapeFix_Edge` composition | Absent | Technical audit detail + Design Review |
| Heal Global | `ShapeFix_Shape` | Present | Category A QA only |
| Validate | `BRepCheck_Analyzer` plus topology traversal | Present baseline | Add exact gap metrics only through approved scope |

The persistent ADR-073 entity model exists in
`lib/core/professional_topology/models/topological_entity.dart`, and accepted
surface results are materialized by the operational controller. The absence is
in operator exposure and workflow, not a justification for a second topology
model.

## Surface Analysis and Quality audit

`GeomLProp_SLProps` currently provides curvature, Gaussian curvature, normal
and draft samples through the existing OCCT bridge. This data can support a
quality report. It does not by itself satisfy visual Zebra, Reflection,
Curvature, Gaussian or Draft Analysis.

Professional visual analysis still requires a Design Review defining:

- per-fragment/per-vertex scalar transport into the existing display mesh;
- color maps, stripe/reflection parameterization and legends;
- live update triggers and cache invalidation;
- selection/highlight interaction;
- restoration of the normal material after Cancel;
- quality percentage formula, thresholds and reproducible diagnostics.

No new renderer, Scene Graph or parallel display pipeline is authorized. The
analysis must be a display mode of the existing viewport and existing scene
projection.

## Inspector, Assistant, Explorer and performance

The current Category B task panel exposes parameters and the operational
controller produces impact/diagnostic fields. The expanded requirements are not
fully demonstrated for every new topology and analysis command.

Required invariants for future implementation:

1. Preview owns only a transient kernel result and transient viewport state.
2. Apply creates the definitive `ShapeHandle` and mutates only affected
   document entities through the established document command path.
3. Cancel destroys all transient handles and restores display state.
4. Inspector reports input IDs, operation parameters, output topology,
   tolerances, affected entities and status.
5. Assistant remains consultive and derives messages from the same operation
   report.
6. Explorer projects official Curve/Wire/Boundary/Face/Shell/Body document
   entities; it does not infer topology from drawings.
7. Camera interaction or analysis display must not rebuild Runtime, BVH or the
   complete Scene Graph.

## Required lifecycle from this audit

1. Keep Category A frozen and complete its pending Release QA separately.
2. Keep the already implemented Category B code unchanged until its stable
   Release smoke can be executed.
3. Produce a **Design Review addendum** only for newly introduced or expanded
   behavior:
   - Offset four-mode workflow and explicit per-Boundary wall selection;
   - Unsew Face/Selected/All;
   - Replace Face and Delete Face;
   - dedicated Split Face workflow;
   - Heal Local;
   - Surface Analysis display modes and Surface Quality indicator.
4. After approval, implement only the approved gaps using the official OCCT
   routes listed above and the existing runtime/document/scene pipeline.
5. Enter Feature Freeze, execute the complete Windows Release smoke, then QA
   and operator review.
6. Keep Category C blocked until its separate audit is explicitly authorized.

## Audit conclusion

The current product contains substantial Category A and Category B kernel
implementation, but the latest official G-109 specification is **not yet fully
operational**. The exact blockers are the expanded Offset contract, missing
topology-edit commands, incomplete deterministic region retention for Boundary
operations, and absent professional viewport analysis modes. These are product
gaps, not reasons to alter the consolidated architecture.

No product code was modified during this audit.
