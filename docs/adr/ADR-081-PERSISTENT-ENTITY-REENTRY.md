# ADR-081 — Persistent Entity Re-entry Contract

Status: Accepted — permanent rule

## Decision

Every authored FLCAD entity has one stable identity and one true definition.
Double-clicking its Explorer root re-enters the environment that owns that
definition. Re-entry edits the existing entity and its existing children; it
must never create a replacement entity or silently duplicate geometry.

This contract applies to Sketches and to every present or future authoring
domain, including Curves, Surfaces, Topology, Shells, Solids and features.

## Required interaction

- Single click selects and inspects.
- Double click re-enters the owning authoring workspace.
- The original ID, parameters, references, constraints and child IDs survive.
- New child operations are appended to the same authoring root.
- Finish exits the workspace without destroying its edit history.
- A domain without an implemented editor reports that explicitly; it must not
  imitate editing by creating a copy.

Every future authored root must publish `authoringRoot: true` and its
`authoringWorkspace` in the document projection, then register its re-entry
handler through the common entity-edit activation path.

## Invariant

Open → edit → finish → reopen preserves the same persistent entity ID.
