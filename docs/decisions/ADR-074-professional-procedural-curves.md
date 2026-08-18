# ADR-074 — Professional Procedural Curves

Status: APPROVED

## Context

ADR-072 made `Curve` a first-class document entity and ADR-073 established the
official `Vertex -> Edge -> Wire -> Face -> Shell -> Solid` topology. Mechanical
reverse engineering also needs curves generated from editable parameters rather
than drawn as Sketch geometry.

## Decision

`ProceduralCurve` is a first-class `CadDocument` entity and a specialization of
the official professional Curve domain. It is not Sketch geometry and it is not
a display-only polyline.

Every committed procedural curve owns:

- an OCCT-backed `ShapeHandle`;
- its official Edge/Wire topology;
- editable parameters and revision history;
- source-reference associations and `current`, `outdated`, or `detached` state;
- persistence and restoration data;
- the geometric evaluation capabilities defined by ADR-072.

Official families are Helix, Spiral, Conical Helix, Variable Pitch Helix,
Variable Radius Spiral, Spring, and Composite Procedural Curve. Multi-start
Helix supports one through four starts.

## Kernel mapping

The existing analytic `HelixCurve3` is not an implementation of this ADR. It
has no ShapeHandle, persistence, topology, or OCCT ownership and must not be
used as an alternative kernel.

The OCCT implementation shall use official geometry and topology primitives:

- cylindrical/conical helices: a parametric `Geom2d_Curve` on the corresponding
  `Geom_Surface`, materialized as `TopoDS_Edge` by
  `BRepBuilderAPI_MakeEdge(Geom2d_Curve, Geom_Surface, first, last)`;
- variable laws and non-analytic families: official OCCT BSpline construction
  (`GeomAPI_Interpolate` or `GeomAPI_PointsToBSpline`, as appropriate), followed
  by `BRepBuilderAPI_MakeEdge`;
- one or more generated Edges assembled into the official Wire with the
  existing kernel Wire builder.

The bridge must return real kernel-owned shapes. Sampled points may support an
OCCT fitting operation or display tessellation, but are never the committed
geometry by themselves.

## Input references

Center accepts Point, Vertex, or Origin. Axis accepts Axis, linear Edge, Line,
or Coordinate System. Reference changes mark the procedural curve `outdated`;
regeneration occurs only after operator confirmation.

## Geometry contract

Procedural curves expose the same evaluator contract as every Professional
Curve: point/parameter, tangent, normal, binormal, curvature, local radius,
closest point, arc length, projection, intersection, tangency, and G0/G1/G2
continuity. These results come from the official OCCT curve owned by the Edge,
not from Sketch or viewport data.

## Workbench integration

All geometry-compatible commands accept Procedural Curve directly. The common
input resolver transparently reuses its Edge or Wire ShapeHandle for Loft,
Sweep, Fill, Patch, Blend, Extrude, Revolve, and surface editing. The operator
never performs a manual conversion.

Explorer placement is `Curves / Procedural`. Preview is transient; Apply commits
the document entity and topology, while Cancel discards only the preview.

## Consequences

No separate procedural kernel, document, scene graph, or modeling pipeline is
permitted. Adding the document model alone does not make a family operational:
each family requires an OCCT bridge operation, ShapeHandle persistence,
topological materialization, controller integration, UI preview/editing, and a
Release Windows smoke test.

