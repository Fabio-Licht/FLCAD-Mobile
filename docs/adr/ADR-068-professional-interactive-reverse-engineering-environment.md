# ADR-068 — Professional Interactive Reverse Engineering Environment

## Status

Accepted as interaction architecture; operational scope is limited to tools backed by certified public engine contracts.

## Decision

Interactive modeling uses one explicit state machine: selection → highlight → tool activation → validated preview → editable parameters → user confirmation → B-001D Command Manager → certified engine/kernel → synchronized scene consumers → undo stack.

`InteractionManager` cannot commit without a current preview in `awaitingConfirmation`. `EngineeringPreviewEngine` rejects previews without evidence or bounded confidence. Geometry is never changed by selection, highlight, navigation, parameter editing, or preview.

## Viewport and selection

The viewport controller owns selection, highlight, transparent preview and camera state. Replace, CTRL toggle and SHIFT additive selection share one deterministic selection service. `ExplorerSync` uses the same controller, providing bidirectional identity synchronization without duplicating selection state.

Orbit, pan, zoom and fit update camera state incrementally. No scene reload, timer, polling, worker or isolate is introduced.

## Tools and integration

Tools are registered with allowed selection types, default parameters, a preview callback and a commit callback. Preview and commit callbacks are adapters only: engineering fitting, recognition, reference proposals and surface creation remain responsibilities of their certified modules. Final commits pass through `ModelingCommandAdapter` and B-001D.

## Capability boundary

The architecture supports plane, cylinder, cone and sphere workflows when a certified engine supplies its candidate and kernel preview. It does not synthesize candidates from UI data. Advanced operations requiring dedicated topology controls remain future G-013 work. Reports, CAM, Scan Studio and mobile interaction remain R-001, G-014, G-016 and G-017 respectively.

## REV.2 functional capability audit

The REV.2 MMVP is not certified complete. Public engines exist for professional/surface recognition, Smart Reference proposals, 2D sketch editing and constraints, analytic surface generation, Loft/Sweep, Fill/Patch and surface operations. They cannot be exposed as executable desktop tools until the viewport supplies their certified input contracts:

- Recognition requires region-level hit-testing and either `MeshEntity` or `RecognitionContext` built from the selected kernel mesh.
- Smart References requires an `EngineeringFeatureSession`; accepting a candidate remains consultative and does not create reference CAD geometry. A separate approved mapping into `ReferenceEngine` is required.
- Sketch 2D requires a real sketch canvas and point/snapping/dimension interaction. No dedicated certified Sketch 3D workflow API exists.
- Surface Generation requires an approved `SurfacePlan` candidate. Surface editing requires `PatchEntity`, topology and quality reports.
- Loft and Sweep exist in Transition Features but require section/path selection and their dedicated parameter UI.

`ModelingCapabilityRegistry` is the authoritative desktop exposure gate. Only capabilities marked `integrated` may be shown as executable. This prevents placeholders, artificial candidates and simplified algorithms.
