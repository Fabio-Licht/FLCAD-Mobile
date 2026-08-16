# ADR-069 — Engineering Interaction Bridge

## Status

Accepted with explicit contract-chain limits.

## Decision

Viewport and Explorer code must not call engineering engines directly. `lib/app/engineering_bridge` is the only UI-facing translation boundary. It owns reusable kernel-mesh selections, ray hit-testing, connected mesh-region construction, validation, adapters and incremental synchronization.

The Bridge never classifies geometry. `RegionClassifier` classifies only the selection container (triangle, region or CAD entity). Analytic classification remains exclusively in Professional Recognition and Surface Recognition.

## Contracts

A `BridgeSelection` retains real kernel nodes, triangle indices and optional CAD identity. `MeshRegionBuilder` validates indices, rejects degenerate or disconnected selections and produces bounds, area, normals, connectivity, ordered vertices and a reproducible fingerprint. `RecognitionBridge` performs a lossless translation into the existing `RecognitionContext`.

## Engine adapters

- Recognition calls `ProfessionalRecognitionApi` with the translated region.
- Smart Reference calls its API only when an official `EngineeringFeatureSession` already exists. Recognition output is evidence, not a replacement for that required contract.
- Reference creation requires explicit confirmation, an evidence-backed approved candidate, a category-compatible `ReferenceRecipe`, and calls only `ReferenceApi`. Undo/delete and redo/restore use that same API.
- Sketch creation requires an explicitly approved `PlaneGeometry`; the bridge creates and opens the session through `SketchEngineApi`.
- Surface generation requires explicit confirmation, a non-empty Sketch and an approved `SurfacePlan`; it delegates to `SurfaceGenerationApi`.

Transition, Advanced Surface and Surface Operations already exist, but remain awaiting their section/path/patch/topology/quality adapters. No synthetic input is created.

## Synchronization and runtime

Explorer state is updated incrementally by stable entity ID. Viewport selection and preview reuse the B-001E controller without scene reconstruction. Assistant messages require evidence and remain consultative. Runtime initialization and execution are passive: no timers, polling, workers or isolates.

## Approval boundary

The architecture and core region-to-recognition path are implemented. The sprint is not certified complete until native screen-coordinate ray construction, hypothesis selection, Engineering Feature production and approved Smart Reference-to-recipe mapping are connected in the Windows executable.

## G-013 completion update

`CameraPicking` now performs homogeneous unprojection from screen coordinates using the actual inverse view-projection matrix and produces the ray consumed by `MeshHitTesting`. `IntelligenceChainBridge` losslessly maps numeric and vector parameters from accepted professional recognition candidates into `PrimitiveObservation`, then invokes the official Primitive Intelligence and Engineering Feature Intelligence APIs. It does not recalculate or reclassify geometry.

The executable still lacks a renderer-owned view-projection matrix and native per-triangle event wiring. Smart Reference-to-`ReferenceRecipe` conversion also has no certified policy contract: candidate categories alone do not specify builder method, source `SmartRegion` or recipe parameters. These named gaps prevent certification of the complete G-013 workflow.

## G-100 production-readiness update

The official Smart Regions analytics and persistence path is now reused by `MeshRegionSmartRegionAdapter`; `SmartReferenceRecipeMapper` produces only recipes supported by Reference Engine and requires approved vectors where the candidate does not contain enough geometry. `CadSceneGraph` and `ReferenceSceneAdapter` provide stable incremental scene identities. Professional picking now uses `MeshBvh`, because the existing geometric-kernel `KDTree` delegates to a linear index and the existing BVH/Octree declarations are interfaces only.

OpenCascade and `CadBuilderApi` already expose sewing and closed-shell solid creation. A production BRep orchestration cannot yet satisfy G-100 undo/redo because `CadBuilderEngine` implements `undo()` but has no `redo()` contract. The desktop renderer also remains `_MeshViewportPainter`, so it cannot supply the view/projection matrices or consume the CAD scene graph.
