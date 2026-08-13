# Shape Validation

Validation is selected by logical shape type:

- Vertex and Edge: degeneration;
- Wire: closure and orientation;
- Face: closure, orientation and degeneration;
- Shell and Solid: manifold state, closure, orientation and degeneration.

Kernel messages become structured diagnostics. Any error triggers transaction rollback and prevents persistence. Warnings remain attached to the audited entity.

