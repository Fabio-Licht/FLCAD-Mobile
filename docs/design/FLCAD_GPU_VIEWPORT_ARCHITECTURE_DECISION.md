# FLCAD GPU Viewport — Architecture Decision

Status: architecture accepted; implementation deferred to FLCAD 2.0.

Program classification: **Rendering Engine Program** — not a G-109 Sprint.

Scope: Rendering Benchmark G-109V. This document makes no change to Runtime,
CadDocument, ShapeHandle or GeometryKernelAPI.

## Decision

Approximately 90% of the Geomagic visual benchmark is not achievable while the
model remains rendered by the current Flutter `CustomPainter`/`Canvas` path.
Canvas remains appropriate for the application shell, toolbar, Explorer,
Inspector, labels, triad and 2D overlays. The shaded 3D model requires a
dedicated GPU viewport.

The recommended Windows architecture is a native Direct3D 11 renderer exposed
to Flutter as an external GPU texture. Flutter's Windows embedder officially
supports `kFlutterDesktopGpuSurfaceTypeD3d11Texture2D` and
`kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle`; the UI can therefore remain in
Flutter while the 3D image is produced natively.

No G-Buffer, deferred rendering, SSAO, HDR tone mapping or GPU viewport work may
start until this decision is approved.

## Roadmap decision

The architecture is approved as the strategic rendering direction, but its
migration is explicitly outside the current project phase. The current priority
remains completion of the full Reverse Engineering workflow, validation in real
use, platform stabilization and identification of actual operational
bottlenecks.

The Rendering Engine Program may start only when all three conditions are met:

1. G-113 is complete.
2. FLCAD is being used in production.
3. Measured expected gains justify the engineering investment.

Until then, the Flutter Canvas viewport remains the production baseline. Its
known quality ceiling relative to the Geomagic benchmark is consciously
accepted. Incremental work may improve clarity and stability within that
ceiling, but must not initiate a hidden GPU migration or introduce the deferred
program components.

## Why Canvas cannot reach the target

The current path reduces geometry to projected 2D vertices and interpolated
colors before rasterization. FLCAD does not control a 3D depth buffer,
per-fragment normals, shader stages, multisampled 3D edges, ID buffers or
multi-pass composition. These are structural requirements for preserving the
visual signatures of planes, cylinders, fillets and curvature transitions.

Further Canvas tuning can improve color, silhouettes and presentation, but it
cannot reliably provide:

- perspective-correct per-pixel engineering lighting;
- robust hidden-surface removal for arbitrary meshes;
- crease-aware normal use at the fragment stage;
- specular response that follows curvature rather than tessellation;
- geometry-aware AO and edge detection;
- depth-correct transparency and selection;
- stable quality on large reverse-engineering meshes.

Expected Canvas ceiling: roughly 45–60% of the benchmark, depending on mesh
quality. This is an engineering estimate, not an operator approval score.

## Architectural impact

### Components retained

- Flutter application shell and themes;
- toolbar, Explorer, Inspector and dialogs;
- CadDocument and Runtime contracts;
- ShapeHandle and GeometryKernelAPI;
- existing scene entity identities and operator commands;
- Flutter overlays where depth interaction is unnecessary.

### Components introduced

- `CadViewportRenderer` presentation boundary;
- Windows native rendering plugin;
- D3D11 device, context and render-target lifecycle;
- Flutter external GPU texture registration;
- render thread independent from the Flutter UI thread;
- persistent vertex/index/normal/attribute buffers;
- depth and multisample targets;
- incremental scene-delta protocol;
- GPU picking/ID request protocol;
- device-loss, resize and resource-recovery handling;
- Canvas renderer retained temporarily as a fallback.

### Data flow

```text
CadSceneGraph snapshot/delta
        ↓
CadViewportRenderer boundary
        ↓ platform channel / native FFI boundary
Windows D3D11 renderer
        ↓
GPU buffers + depth-tested render passes
        ↓
D3D11 shared texture
        ↓
Flutter Texture widget
        ↓
Flutter overlays and desktop UI
```

Full mesh arrays must be transferred only on creation or geometry change.
Camera, visibility, selection and material changes travel as small deltas.

## Alternatives

| Alternative | Benchmark potential | Cost | Main benefit | Main limitation |
|---|---:|---:|---|---|
| Continue Flutter Canvas | 45–60% | Low | No native migration | Structural ceiling already reached |
| Flutter fragment shader over Canvas data | 55–70% | Medium | Some per-pixel tonal control | Still lacks a complete indexed 3D/depth pipeline |
| Native OCCT V3d/AIS window | 75–90% | Medium/high | Mature CAD visualization and existing OCCT dependency | Harder Flutter composition, custom mesh-analysis styling and cross-platform control |
| OpenGL native texture | 80–95% | High | Portable rendering model | Additional Windows interop and driver surface |
| Vulkan renderer | 90%+ | Very high | Maximum control and future portability | Highest implementation and maintenance cost |
| D3D11 external GPU texture | 90%+ | High | Best Windows/Flutter integration and mature tooling | Windows-specific renderer must be maintained |

## Recommended alternative

Use D3D11 with a Flutter external GPU texture for the Windows Release.

Reasons:

1. Windows is the current approval platform.
2. Flutter officially exposes D3D11/DXGI GPU surface texture types.
3. The model can have a real depth buffer and programmable shaders without
   moving the rest of the desktop application out of Flutter.
4. Scene, selection and camera contracts can remain renderer-independent.
5. A later renderer for another platform can implement the same presentation
   boundary.

OCCT V3d should be evaluated as a bounded prototype only if it can render into
the same external-texture composition path. Making a native child window the
primary UI surface is not recommended because it complicates Flutter overlays,
focus, DPI, clipping and event coordination.

## Indicative cost

The estimates below are engineering effort, not calendar promises or financial
quotes.

| Delivery level | Indicative effort | Result |
|---|---:|---|
| Architecture spike | 2–3 engineer-weeks | External texture, resize, one depth-tested mesh |
| Usable GPU viewport foundation | 6–10 additional engineer-weeks | Scene updates, camera, depth, MSAA, lifecycle and fallback |
| Rendering Benchmark candidate | 8–12 additional engineer-weeks | robust normals, technical material, lighting, specular, edges and selection |
| Production hardening | 6–10 additional engineer-weeks | large-mesh performance, device loss, diagnostics, tests and packaging |

Indicative total: 22–35 engineer-weeks. Parallel specialists can shorten
elapsed time but not remove integration and validation work.

Continuing Canvas would cost less initially (approximately 2–4 engineer-weeks
for further tuning) but would not remove the architectural ceiling and would
likely be discarded during a later migration.

## Benefits

- geometry information remains available until fragment shading;
- planes, cylinders and fillets can receive distinct, continuous visual
  signatures;
- triangulation can be suppressed without suppressing real scan texture;
- correct occlusion and stable silhouettes;
- depth-aware selection, preview and transparency;
- predictable path to controlled specular, AO, edges, gamma and tone mapping;
- lower CPU work during camera navigation;
- persistent buffers suitable for large engineering meshes;
- Flutter UI remains intact.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Native renderer increases platform complexity | Narrow renderer interface and Windows-only first milestone |
| Device/driver differences | D3D11 feature-level baseline, adapter diagnostics and software fallback |
| Flutter/native synchronization stalls | Dedicated render thread and delta-based updates |
| Large mesh transfer cost | Persistent buffers, chunked upload and immutable geometry IDs |
| Visual regressions | Fixed benchmark model, camera poses and side-by-side captures |
| Picking diverges from displayed geometry | GPU ID buffer generated from the same depth-tested draw |
| Migration disrupts current users | Keep Canvas fallback until GPU acceptance gates pass |

## Migration plan and gates

### Phase 0 — Benchmark contract

- Freeze the official reference images.
- Define one FLCAD test mesh and matching camera poses.
- Record visual acceptance checks for plane, cylinder, fillet and transition.
- No renderer implementation.

Gate: operator approves the comparison fixture.

### Phase 1 — Renderer boundary

- Introduce a presentation-only renderer interface.
- Place the existing Canvas implementation behind it without visual change.
- Define immutable mesh upload and small scene-delta messages.

Gate: current Release behavior and automated tests remain unchanged.

### Phase 2 — GPU integration spike

- Register a D3D11 external texture with Flutter.
- Render one indexed mesh with depth testing.
- Validate resize, DPI, frame notification and cleanup.
- Do not implement AO, HDR or deferred rendering.

Gate: stable Release smoke test on supported Windows adapters.

### Phase 3 — GPU viewport foundation

- Persistent vertex and index buffers.
- Camera matrices, depth buffer, MSAA and visibility.
- Scene-delta synchronization and Canvas fallback.

Gate: navigation remains fluid and the displayed geometry is complete.

### Phase 4 — RENDER-002 and RENDER-001

- Build the crease-aware, scan-aware normal pipeline.
- Re-run tonal separation using per-fragment normals.
- Validate planes, cylinders, fillets and transitions before proceeding.

Gate: operator approves RENDER-001 and RENDER-002 together because they are
structurally dependent.

### Phase 5 — Material and lighting

- Technical matte material.
- Controlled per-pixel specular.
- Engineering key/fill/ambient lighting.

Gate: RENDER-003, RENDER-004 and RENDER-009 visual approvals.

### Phase 6 — Depth-aware effects

- Geometry-aware AO.
- Feature/silhouette edges.
- ID-buffer selection and preview.
- Contact shadow only where geometrically valid.

Gate: no tessellation emphasis, halo or hidden-selection error.

### Phase 7 — Output transform and rollout

- Explicit linear workflow, gamma and technical tone mapping.
- Performance qualification on representative large meshes.
- Make GPU renderer default only after operator acceptance.
- Retain Canvas fallback for recovery during the transition.

## Future authorization required

Acceptance of this architecture records the strategic direction only. It does
not authorize implementation of G-Buffer, deferred rendering, SSAO, HDR tone
mapping or any GPU viewport stage. A new explicit authorization is required
after the roadmap entry conditions are satisfied.
