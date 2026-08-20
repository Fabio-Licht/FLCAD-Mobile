# ADR-080 — Docking Window Standard

Status: Approved

## Decision

Every operational tool window in FLCAD uses one workspace-window contract. The Explorer organizes, Tool Windows execute work, the Inspector reports context, and the viewport remains dominant.

## Standard panel contract

Explorer, Property Inspector, Engineering Assistant and future docked panels provide the same lifecycle controls:

- collapse to a narrow recoverable side tab;
- expand and restore width;
- pin and unpin;
- close without losing the recovery path;
- retain a stable title, icon and content region.

## Standard Tool Window contract

Sketch, Surface, Transform, Measure, Inspection, Alignment and every future operational tool use the shared Tool Window host. A Tool Window provides:

- semantic title and engineering icon;
- move by its title bar;
- resize from its resize grip;
- dock and return to floating mode;
- pin state;
- close and explicit recovery;
- a scrollable content region independent from the Explorer.

## Workspace contract

The workspace manager owns only layout state: visibility, position, size, collapsed state, pin state and dock state. It never owns CAD commands, document entities, geometry or camera state.

Workspace profiles such as Reverse Engineering, Sketch, Surface, Inspection and CAM will compose the same standardized panels. Adding a profile must not create a new window behavior.

## Dependencies

Tool content may depend on Platform services. The window host depends only on presentation contracts. Neither the Render Engine nor the Camera Contract depends on workspace windows.

## Permanent rule

No operational tool may be embedded in the Explorer or introduce a custom window lifecycle. Any exception requires a new ADR.
