# G-120.4 — Coordinate System & Spatial State Audit

Status: implemented and verified.

## Spatial contract

FLCAD uses one right-handed world coordinate system (WCS): origin `(0, 0, 0)`,
unit axes `X=(1,0,0)`, `Y=(0,1,0)`, `Z=(0,0,1)`, and `X × Y = Z`.
Stored geometry, SceneGraph nodes, Sketch planes, the triad, ViewCube, standard
views, Flutter camera and Direct3D camera now use that same contract.

There is no presentation/model transform between stored geometry and the
SceneGraph. View and projection matrices change the presentation only. The
native renderer uses right-handed DirectX view, perspective and orthographic
matrices, so it does not mirror the Flutter overlays or the WCS.

## Persistence boundary

Permanent project data:

- geometry and its real coordinates;
- Sketch entities and permanent plane/support references;
- curves, surfaces and permanent references;
- entity names, layers and permanent parameters.

Transient, never project data:

- presentation and projection offsets;
- preview, hover and selection;
- dynamic transform previews;
- temporary camera state;
- temporary Sketch/editor state and its camera snapshot.

The Sketch camera snapshot is deliberately memory-only. It stores the complete
camera pose/lens/presentation needed to return from Sketch during the current
session, but it is cleared at the project boundary and is never serialized.

Legacy project payloads are sanitized on open. Known transient fields are
removed, legacy selection is reset, and the normalized permanent document is
saved again. Therefore the recovery also applies to projects created before
this sprint.

## Open-project sequence

The enforced sequence is:

1. clear the previous runtime and all transient projection/selection state;
2. load permanent project geometry;
3. rebuild the complete SceneGraph;
4. recalculate the bounding box from rebuilt visible entity coordinates;
5. clear temporary presentation state again at the UI/camera boundary;
6. restore the deterministic workspace camera from the recalculated bounds;
7. publish the viewport.

`Fit` uses live bounds recalculated from the SceneGraph. It does not consume a
persisted bounding box.

## Camera and views

Navigation commands cross one camera contract through the navigation adapter
and `CadCameraController`. The native bridge receives the same `Eye`, `Target`,
`Up`, FOV, near/far planes, projection mode, orthographic height and projection
offsets.

Standard world directions (`Eye - Target`) are:

- Top `+Z`, Bottom `-Z`;
- Front `-Y`, Back `+Y`;
- Right `+X`, Left `-X`;
- ISO `(+X,-Y,+Z)`.

The triad projects the WCS using the shared camera. The ViewCube derives its
faces from the same camera basis and invokes those same standard-view commands.
World planes remain protected WCS references and use transparent presentation
without changing their position or orientation.

## Mandatory verification

Automated tests cover:

1. imported STL coordinates before and after save/close/open;
2. geometry and camera before and after entering/leaving Sketch;
3. Pan, Fit, save and open, including removal of presentation offsets;
4. Orbit, save and open, proving that only camera orientation changes;
5. every standard view, save/open orientation, WCS handedness and orthogonal
   camera basis.

The native camera contract additionally validates World/View/Projection/WVP,
clip coordinates and Pan rigidity. All audit and regression tests pass.

