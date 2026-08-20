# ADR-083 — Feature Lifecycle Contract

Status: Accepted — permanent platform architecture

## Decision

Every authored FLCAD Feature is a living project object with one permanent
identity. Creation, editing, closing, saving, reopening, re-entry and further
editing mutate the same Feature definition. Re-entry never creates replacement
geometry.

Every Feature persists the `flcad.feature-lifecycle` contract containing:

- permanent Feature ID and owning workspace;
- lifecycle state and monotonically increasing revision;
- creator and ordered history events;
- parameters, references and child IDs;
- dependencies and reverse dependents;
- stable Explorer parent and order;
- `doubleClick` as the official activation gesture;
- `flcad.geometry-constraint-solver/v1` as the exclusive update contract.

The CAD document is the authoritative lifecycle store. The lifecycle projector
normalizes every authored entity at the central document mutation boundary and
rebuilds reverse dependencies on load. This prevents domain-specific lifecycle
copies and guarantees that an Explorer Feature appears once, keyed by its ID.

## Editing rule

Domain adapters may interpret Line, Arc, Sketch, Surface or future feature
types. The Feature update gateway receives only the abstract Geometry
Constraint Solver contract. A domain adapter applies a successful propagation
plan atomically; a solver conflict must leave the Feature unchanged.

## Re-entry rule

Single click selects and opens the Inspector. Double click transitions the
existing Feature to `editing` and opens its owning workspace. Unsupported
replacement or duplicate-based editing is forbidden.

## Persistence invariant

The following sequence preserves the exact Feature ID, definition, tree
position and history:

`create → edit → save → close → project reopen → double click → edit → save`

Undo and Redo restore lifecycle state and definition snapshots without changing
the Feature ID.
