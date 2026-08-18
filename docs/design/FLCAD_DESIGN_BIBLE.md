# FLCAD Design Bible

Status: normative for G-109R and subsequent operator-experience work.

## Official FLCAD philosophy

> O FLCAD não pretende reinventar a forma de operar um CAD.
>
> O FLCAD pretende reinventar a forma de fazer Engenharia Reversa.

Operational consequence: navigation, selection, viewport, WCS, sketch and
editing must feel immediately familiar to an experienced CAD operator. Product
differentiation belongs in reverse engineering, Mesh Intelligence, AI,
Mesh-to-CAD integration and automation—not in unfamiliar mouse gestures or
ambiguous visual feedback.

## Governing rule

FLCAD does not invent interaction patterns already consolidated by professional
CAD systems. A change is approved only when it is functional, visually clear,
operationally familiar and verified in a Windows Release build by an operator.

Reference ownership:

| Area | Reference | FLCAD innovation allowed |
|---|---|---|
| Navigation | CATIA | No |
| Viewport and WCS | CATIA | No |
| Sketch | CATIA | No |
| Curves and surfaces | Tebis | No |
| Reverse engineering | Geomagic Design X | Yes |
| Mesh intelligence | FLCAD | Yes |
| AI and automation | FLCAD | Yes |

## Evidence contract

Every UX item must include these four artifacts before approval:

1. `reference.png`: licensed or operator-provided capture of the reference CAD.
2. `flcad-before.png`: capture from the last approved FLCAD Release.
3. `differences.md`: observable differences, without generic wording.
4. `flcad-after.png`: capture from the candidate FLCAD Release.

Store evidence under `docs/design/evidence/<item-id>/`. Do not copy third-party
screenshots into the repository without permission; a source URL and capture
date may be recorded in `differences.md` instead.

## NAV-001 — CATIA mouse navigation

Reference behavior:

| Operation | Required FLCAD behavior |
|---|---|
| Select | Left click |
| Set rotation center | Middle click at the pointed location |
| Pan | Hold middle button and drag |
| Orbit | Hold middle button, then hold left or right button, and drag |
| Wheel zoom | Forward zooms toward the pointer; backward zooms out |
| Fit View | `F` and the Fit command frame all visible geometry |
| Zoom gesture | Middle button plus left/right sequence and vertical drag |
| Navigation selection | Existing preselection remains intelligible while navigating |

Implemented G-109R candidate behavior: middle-button drag pans; middle combined
with left or right drag orbits; a middle click on selectable geometry sets the
rotation center; wheel zoom uses the pointed geometry as its anchor; left click
remains selection; and Fit View frames all visible model geometry. Operator
validation against CATIA remains mandatory before approval.

Objective: implement the table exactly, preserve left-click selection, and keep
Fit View as the safe recovery path. No alternative navigation profile is in scope.

### Manipulation perception

> O operador nunca devera sentir que esta movimentando uma camera. O operador
> devera sentir que esta segurando a peca.

This is an acceptance principle, not a velocity or easing requirement. Camera
dynamics must not be used to mask an incorrect base interaction. Gain,
acceleration, deceleration, damping and sensitivity remain unchanged until the
cause of the camera-like perception has been identified and corrected.

Official behavioral reference: Dassault Systèmes 3DEXPERIENCE Mouse Controls,
CATIA Profile, and Zoom/Pan/Rotate/Reframe user assistance.

## PICK-001 — Preselection and selection

Reference sequence:

`cursor -> preselection -> highlight -> click -> selection -> persistent visual confirmation`

Required distinctions:

| State | Visual contract |
|---|---|
| Available | Normal category identity |
| Preselected | Visible contour/glow with increased edge thickness |
| Selected | Persistent color distinct from preselection |
| Hidden/occluded | Never presented as the direct hit unless explicitly requested |

Current FLCAD baseline: entity-level hover and selection exist for tessellated
objects, planes, curves, sketches and sections. Face/edge/wire sub-entity identity,
occlusion-aware ordering and a stacked-selection navigator remain unapproved.

Objective: match CATIA's geometry-view prehighlight and highlight distinction,
including synchronization with the Explorer selection.

## VIEW-001 — Viewport

Reference: CATIA V5 visual hierarchy and operator legibility.

Official G-109V visual evidence: operator video `Gravando TESTE PAN GEOMAGIC
COM AS CONFIGURAÇÕES DO CATIA.mp4` (Geomagic Design X, CATIA profile). The
video governs perceived solidity, contrast, depth, lighting softness and visual
stability. Every visual change must answer: **does this make the geometry easier
to read?** If it does not, it is out of scope.

Acceptance checks:

- shaded geometry is opaque unless transparency is explicitly active;
- static rendering has antialiased silhouettes and stable contrast;
- selected faces and edges remain distinguishable from preselection;
- Mesh, Section, Sketch, Curve, Preview and Surface each have a stable identity;
- dynamic navigation does not blank the viewport or lose the complete model.

Current FLCAD baseline: opaque shaded mesh, per-vertex lighting, category colors
and hover feedback exist. A GPU depth buffer and face/edge-level highlight are
still required for professional parity.

### G-109V visual hierarchy

| Category | Normal identity | Interactive identity |
|---|---|---|
| Mesh | neutral steel blue, opaque shaded volume | cyan hover, amber selection |
| Surface | restrained teal with softer fill | cyan hover, amber selection |
| Section / Curve | fine technical blue line | cyan hover, amber selection |
| Sketch | fine green line | cyan hover, amber selection |
| Spline | fine violet line | cyan hover, amber selection |
| Preview | translucent orange | cyan hover, amber confirmation |
| WCS | low-opacity RGB references | highlight only on interaction |

Lighting uses a soft key, fill and ambient contribution. Ambient occlusion is
subtle and limited to improving the reading of face meetings. Background
contrast remains subordinate to geometry. Sketch grid is visible only in
Sketch, with minor lines, major lines and local axes clearly distinguished.

### Rendering roadmap boundary

The dedicated GPU viewport architecture is accepted for **FLCAD 2.0 —
Rendering Engine Program**, not for G-109. It remains deferred until G-113 is
complete, FLCAD is in production use, and measured benefit justifies the
engineering investment. The Flutter Canvas viewport is the conscious current
baseline; visual improvements must remain within that architecture and must not
silently introduce G-Buffer, deferred rendering, SSAO, HDR tone mapping or GPU
viewport migration work.

## WCS-001 — World coordinate system

Required behavior:

- fixed triad in the lower-left corner;
- X/Y/Z labels and camera-relative orientation;
- discrete world planes with bounded screen footprint;
- axis and plane line weight subordinate to model geometry;
- planes remain easy to preselect despite low visual prominence.

Current FLCAD baseline: the fixed oriented triad and labels exist. World-plane
screen-space bounding and final visual comparison against CATIA are pending.

## SKETCH-001 — Sketch entry and exit

Required sequence:

`select plane -> confirm highlight -> enter Sketch -> orthogonal camera -> local grid -> edit -> exit -> restore prior camera`

Creating a sketch without an explicit, valid support plane is prohibited. The
grid origin and axes must derive from the same persisted support-plane frame.

## Release approval record

For every candidate record:

| Field | Required value |
|---|---|
| Build | Commit/build identifier |
| Platform | Windows Release only |
| Reference evidence | Path or authorized source URL |
| FLCAD before/after | Artifact paths |
| Automated checks | Passed/failed with command |
| Operator result | Exact operator observation |
| Approval | Approved only after professional-CAD-equivalent operation |

“Works” is not an approval result. The operator must be able to navigate,
preselect, select, sketch, edit and recover the view without learning an FLCAD-
specific interaction model.
