# ADR-046 — Professional Continuity & Surface Quality Engine

## Status

Accepted.

## Decision

Surface quality is a read-only stage after Surface Topology. The public `SurfaceQualityKernelAPI` routes every differential measurement through the OpenCascade adapter; the native implementation samples each real `TopoDS_Face` with `BRepAdaptor_Surface` and `BRepLProp_SLProps`. It returns principal, mean and Gaussian curvature, normals, normal variation, reflection/zebra scalars and draft classification. Native handles never escape the adapter.

Patch-to-patch G0/G1/G2 classification is evaluated only when topology contains a shared intersection. G3 is represented in the model for the next platform stage but is not claimed by the current second-derivative sampler. An isolated patch is explicitly `notApplicable`; the system never invents a neighbor or a continuity grade.

The engine cannot alter geometry. It builds a persistent continuity graph, scores surface health, and emits consultative advice with `automaticActions: false`. Bootstrap registration is passive and OpenCascade remains lazy until `RUN CONTINUITY` or an explicit API call.

## Consequences

- Curvature, reflection, zebra and draft evidence derives from native face derivatives and normals, with no fake imagery or geometric fallback.
- Project First persists reports under the eight `CAD/*` quality paths.
- Workspace, Studio, Interactive Reverse, Live Validation, Session, Dashboard and Engineering Intelligence receive projections without taking ownership of geometry.
- G-011 may consume the diagnostics, but any future surface modification requires a separate command and decision.

## Certification

The Release bridge analyzed the official OpenCascade 8.0.1 `bearing.stl` pipeline. It produced one reconstructed patch, one truthful `notApplicable` continuity relation, native curvature/zebra/reflection/draft evidence, quality score `0.7731026170014186`, zero fallbacks and no geometry modification. The native smoke test and 100 deterministic domain pipelines passed.
