# ADR-079 — Navigation Framework

Status: accepted

## Decision

All FLCAD navigation must follow one operational path:

`Input device → NavigationEngine → NavigationCommand → Camera Contract → Camera Snapshot → Viewport`.

`NavigationEngine` exclusively owns gesture interpretation, navigation state,
profiles, transitions, operational context, and priority between selection and
navigation. It never renders geometry, builds matrices, or accesses a graphics
API.

The camera is mathematical. It knows Eye, Target, Up, Distance, projection and
matrices, and executes only high-level commands. It has no knowledge of mouse
buttons, keyboards, touch events, or UI gestures.

Viewports consume Camera Snapshots and render them. Flutter Canvas and Native
GPU may not maintain or interpret their own navigation behavior.

## Required states and commands

The framework defines Idle, Hover, Selecting, Orbiting, Panning, Zooming,
BoxZoom, Seek, Dragging, SketchNavigation and SectionNavigation. Transitions
are explicit.

The camera boundary accepts Orbit, Pan, Zoom, Fit, SetRotationCenter and Focus
commands. Input adapters for mouse, touchpad, SpaceMouse, tablet, VR, API and
macros must produce these same commands.

## Profiles and contexts

CATIA, Geomagic, FLCAD Classic and FLCAD Reverse Engineering are first-class
profiles. Viewport, Sketch, Section, Inspection, Mesh, Surface and Assembly are
first-class operational contexts. Profiles and contexts may change command
interpretation, never camera mathematics.

## Enforcement

New gesture behavior is prohibited in `ProfessionalCadViewportWidget`,
`CadCameraController`, and `NativeViewportHost`. These components may only act
as input adapter, mathematical command target, and snapshot consumer,
respectively. Any exception requires a superseding ADR.
