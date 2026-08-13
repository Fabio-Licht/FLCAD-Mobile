# Solid Builder

`SolidBuilder.fromClosedShell` accepts only a shell whose kernel metadata explicitly reports `closed: true`. The engine then requests solid creation and validates manifold state, closure, orientation and degeneration.

An open or uncertain shell returns `shell-not-closed`; an invalid solid is never committed or persisted.

