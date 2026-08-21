# FLCAD UI Modernization — Sprint Backlog

## Status

**PLANNED — NOT AUTHORIZED FOR IMPLEMENTATION**

This document records the approved design direction and proposed Sprint
breakdown. It does not authorize source-code or interface changes.

## Visual direction

Reference supplied by the operator on 2026-08-21:
`C:\TRABALHO\teste\FLCAD.png`.

The intended workspace composition is:

- professional contextual Ribbon at the top;
- permanent Engineering Explorer on the left;
- dominant central viewport;
- Inspector and Properties on the right;
- collapsible Diagnostics, Timeline and Platform Status panels at the bottom;
- navigation controls adjacent to the viewport;
- visible ViewCube and WCS without obstructing geometry;
- contextual Tool Windows for active commands.

The image is a visual reference, not a requirement to copy every component.
FLCAD interaction contracts and identity remain authoritative.

## Permanent implementation constraints

- Geometry, Solver, Camera Contract, WCS and Feature Lifecycle remain frozen.
- Existing commands keep their current behavior and identity.
- Commands that require selection continue opening their editor before the
  selection is made.
- The viewport remains the largest workspace region.
- Bottom panels must be collapsible.
- Explorer and Inspector must be resizable.
- Layout state must eventually persist per user and workspace.
- Smaller displays must collapse secondary panels automatically.
- Each Sprint requires regression tests before the next one begins.

## Proposed Sprints

### UI-001 — Workspace Shell

Create the structural layout: Ribbon, left Explorer, central viewport, right
Inspector and a collapsible lower region. No command behavior changes.

### UI-002 — Professional Ribbon

Organize existing commands into tabs and functional groups, including icons,
enabled/disabled state and contextual command activation.

### UI-003 — Docking & Resizing

Allow panels to resize, collapse, expand, move and restore to their default
positions without blocking the viewport.

### UI-004 — Contextual Tool Windows

Standardize Sketch, Surface, Fillet, Fill, Sew, Extrude, Revolve and future
editors. Preserve the rule that the editor opens before interactive selection.

### UI-005 — Explorer & Inspector

Consolidate hierarchy, selection synchronization, properties, Feature status
and official double-click reentry.

### UI-006 — Viewport Controls

Organize navigation controls, ViewCube, WCS, rendering modes and viewport
indicators without changing navigation or spatial infrastructure.

### UI-007 — Diagnostics & Timeline

Create collapsible lower panels for geometry health, errors, warnings, Feature
history and reconstruction progress.

### UI-008 — Layout Persistence

Persist panel position, size, visibility and collapsed state per user and per
workspace. Provide a safe Restore Default Layout action.

### UI-009 — Responsive Workspace

Validate different resolutions, Windows display scales and multi-monitor use.
Secondary panels collapse automatically when space is insufficient.

### UI-010 — Visual Consolidation

Unify colors, typography, spacing, iconography, contrast, hover, selection,
disabled state and rendering performance.

### UI-011 — Regression Certification

Run complete smoke and regression validation for Sketch, Surfaces, Solids,
Recognition, selection, Preview, reentry, Undo/Redo, persistence, viewport,
WCS and command windows.

## Recommended execution rule

Begin only with UI-001. After its visual and operational review, authorize the
next Sprint individually. Do not implement the complete redesign in one pass.

